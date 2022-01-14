const {config} = require('../test/config');

describe("NFT <-> Marketplace sales", function() {
    it("Should create and execute marketplace sales", async function() {
      const [deployer, seller, buyer, donator] = await ethers.getSigners();

      // deploy the Marketplace contract
      const Marketplace = await ethers.getContractFactory("Marketplace");
      const marketplace = await Marketplace.deploy(config.feeVault);
      await marketplace.deployed();
      const marketplaceAddress = marketplace.address;
  
      // deploy the NFT contract
      const NFT = await ethers.getContractFactory("NFT");
      const nft = await NFT.deploy(marketplaceAddress);
      await nft.deployed();
      const nftContractAddress = nft.address;
  
      const auctionPrice = ethers.utils.parseUnits("2", "ether");
      const feePercent = await marketplace.getFeePercent();
      const feeAmount = auctionPrice.mul(feePercent).div(10000);
  
      // create two tokens
      const tokenId1 = await nft.createToken("https://www.token-location-on-ipfs.com");
      const tokenId2 = await nft.createToken("https://www.token-location-on-ipfs-2.com");
        
      // a nft approve
      // await nft.approve(marketplace.address, tokenId1, {from: deployer.address});
      // All nft approve
      await nft.setApprovalForAll(marketplace.address, true, {from: deployer.address});

      // put both tokens for sale
      await marketplace.createMarketplaceItem(nftContractAddress, 1, auctionPrice, {value: feeAmount});
      await marketplace.createMarketplaceItem(nftContractAddress, 2, auctionPrice, {value: feeAmount});
        
      // Donate by donator
      const tx = await marketplace.connect(donator).donate({ value: auctionPrice });   
      let events = (await tx.wait()).events;    
      console.log("===donate tx-event::", events);

      // execute sale of token to another user
      await marketplace.connect(buyer).createMarketplaceSale(nftContractAddress, 1, { value: auctionPrice });
  
      // query for and return the unsold items
      items = await marketplace.fetchMarketplaceItems();
  
      // prepare items to show
        items = await Promise.all(
            items.map(async i => {
            const tokenUri = await nft.tokenURI(i.tokenId);
            let item = {
                price: i.price.toString(),
                tokenId: i.tokenId.toString(),
                seller: i.seller,
                owner: i.owner,
                tokenUri
            };
            return item;
            })
        );
        });
  });