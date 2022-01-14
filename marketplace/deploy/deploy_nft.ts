import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {
    deployments: { deploy, get },
    ethers: { getSigners },
  } = hre;

  const deployer = (await getSigners())[0]; 
  const marketplace = await get('Marketplace');
        
  await deploy('NFT', {
    from: deployer.address,
    args: [      
      marketplace.address
    ],
    log: true,    
    skipIfAlreadyDeployed: true,
    autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
  });  
};

func.id = 'deploy_nft'; // id required to prevent reexecution
func.tags = ['NFT'];
func.dependencies = ['Marketplace'];

export default func;