import React, { useState, useEffect } from "react";
import { Button } from "antd";
import { ethers } from "ethers";
import axios from "axios";

const MainUI = ({ loadWeb3Modal, address, tx, priceToMint, readContracts, writeContracts }) => {
  const [collection, setCollection] = useState({
    loading: true,
    items: [],
  });

  const getTokenURI = async (ownerAddress, index) => {
    const id = await readContracts.MoonshotBot.tokenOfOwnerByIndex(ownerAddress, index);
    const tokenURI = await readContracts.MoonshotBot.tokenURI(id);
    const metadata = await axios.get(tokenURI);
    const approved = await readContracts.MoonshotBot.getApproved(id);
    return { ...metadata.data, id, tokenURI, approved: approved === writeContracts.RetroactiveFunding.address };
  };

  const loadCollection = async () => {
    if (!address || !readContracts || !writeContracts) return;
    setCollection({
      loading: true,
      items: [],
    });
    const balance = (await readContracts.MoonshotBot.balanceOf(address)).toNumber();
    const tokensPromises = [];
    for (let i = 0; i < balance; i += 1) {
      tokensPromises.push(getTokenURI(address, i));
    }
    const tokens = await Promise.all(tokensPromises);
    setCollection({
      loading: false,
      items: tokens,
    });
  };

  const burn = async id => {
    const burnTx = await tx(writeContracts.RetroactiveFunding.executeSale(readContracts.MoonshotBot.address, id));
    await burnTx.wait();
    loadCollection();
  };

  const approveForBurn = async id => {
    const approveTx = await tx(writeContracts.MoonshotBot.approve(writeContracts.RetroactiveFunding.address, id));
    await approveTx.wait();
    loadCollection();
  };

  useEffect(() => {
    loadCollection();
  }, [address, readContracts, writeContracts]);

  return (
    <div style={{ maxWidth: 768, margin: "20px auto" }}>
      {address ? (
        <>
          <div style={{ display: "grid", margin: "0 auto" }}>
            <h3 style={{ marginBottom: 25 }}>My collection: </h3>
            {collection.items.length === 0 && <p>Your collection is empty</p>}
            {collection.items.length > 0 &&
              collection.items.map(item => (
                <div style={{ display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto" }}>
                  <img
                    style={{ maxWidth: "150px", display: "block", margin: "0 auto", marginBottom: "20px" }}
                    src={item.image}
                    alt="MoonshotBot"
                  />
                  <div style={{ marginLeft: "20px" }}>
                    {!item.approved && (
                      <Button
                        style={{ display: "block", marginBottom: "10px", minWidth: 100 }}
                        onClick={() => approveForBurn(item.id)}
                      >
                        Approve
                      </Button>
                    )}
                    {item.approved && (
                      <Button style={{ width: "100%", minWidth: 100 }} onClick={() => burn(item.id)}>
                        Burn
                      </Button>
                    )}
                  </div>
                </div>
              ))}
          </div>
          <Button
            style={{ marginTop: 15 }}
            type="primary"
            onClick={async () => {
              const priceRightNow = await readContracts.MoonshotBot.price();
              const txCur = await tx(writeContracts.MoonshotBot.requestMint(address, { value: priceRightNow }));
              await txCur.wait();
              loadCollection();
            }}
          >
            MINT for Ξ{priceToMint && (+ethers.utils.formatEther(priceToMint)).toFixed(4)}
          </Button>
        </>
      ) : (
        <Button key="loginbutton" type="primary" onClick={loadWeb3Modal}>
          Connect to mint
        </Button>
      )}
    </div>
  );
};

export default MainUI;
