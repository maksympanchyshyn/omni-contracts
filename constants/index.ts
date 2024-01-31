export type LzChain = {
  name: string;
  chainId: number;
  lzChainId: number;
  lzEndpoint: string;
};

export const LZ_CHAINS: LzChain[] = [
  {
    name: 'Goerli',
    chainId: 5,
    lzChainId: 10121,
    lzEndpoint: '0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23',
  },
  {
    name: 'Fuji',
    chainId: 43113,
    lzChainId: 10106,
    lzEndpoint: '0x93f54D755A063cE7bB9e6Ac47Eccc8e33411d706',
  },
  {
    name: 'Mumbai',
    chainId: 80001,
    lzChainId: 10109,
    lzEndpoint: '0xf69186dfBa60DdB133E91E9A4B5673624293d8F8',
  },
  {
    name: 'Arbitrum-Goerli',
    chainId: 421613,
    lzChainId: 10143,
    lzEndpoint: '0x6aB5Ae6822647046626e83ee6dB8187151E1d5ab',
  },
  {
    name: 'Optimism-Goerli',
    chainId: 420,
    lzChainId: 10132,
    lzEndpoint: '0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1',
  },
  {
    name: 'Arbitrum One',
    chainId: 42161,
    lzChainId: 110,
    lzEndpoint: '0x3c2269811836af69497E5F486A85D7316753cf62',
  },
  {
    name: 'Optimism',
    chainId: 10,
    lzChainId: 111,
    lzEndpoint: '0x3c2269811836af69497E5F486A85D7316753cf62',
  },
];
