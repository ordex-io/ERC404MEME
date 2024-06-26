import { ethers } from "hardhat";
import { solidityPackedKeccak256, BytesLike } from "ethers";

/**
 * Calculate the DNA to compare it.
 *
 * This is based on the given words and make abi.encodePacked and hash it with keccak256
 */
export function calculateDNA(id_: BigInt, words_: Array<bigint>): string {
  return solidityPackedKeccak256(["uint256", "uint256[]"], [id_, words_]);
}

export function dnaToJsonString(
  variantsName_: string[],
  variantCounters_: bigint[],
  schemaHash_: BytesLike,
  dna_: string
): string {
  const expectedJson: { [key: string]: string } = {};

  // dna_param_value = uint256(keccack256(schema_hash + dna + keccack256(param_name)) ٪ param_variants_count
  variantsName_.forEach((name_, index_) => {
    expectedJson[name_] = (
      BigInt(
        solidityPackedKeccak256(
          ["string", "bytes32", "bytes32"],
          [schemaHash_, dna_, solidityPackedKeccak256(["string"], [name_])]
        )
      ) % variantCounters_[index_]
    ).toString();
  });

  return JSON.stringify(expectedJson);
}

export async function getBlockHash(blockNumber: number | null = null) {
  if (blockNumber === null) {
    blockNumber = await ethers.provider.provider.getBlockNumber();
  }

  const block = await ethers.provider.provider.getBlock(blockNumber);

  if (block && block.hash) {
    return block.hash;
  } else {
    throw `Not block obtained`;
  }
}

export async function getBlockNumber() {
  return await ethers.provider.getBlockNumber();
}

export async function getTimeStamp(
  blocknumber?: bigint | number | null | undefined
): Promise<number> {
  if (!blocknumber) {
    blocknumber = await getBlockNumber();
  }
  const block = await ethers.provider.getBlock(blocknumber);

  if (!block) throw "cannto get current block";

  return block.timestamp;
}

export function nonDuplicateDNA(dnaArray: string[]): boolean {
  return new Set(dnaArray).size === dnaArray.length;
}
