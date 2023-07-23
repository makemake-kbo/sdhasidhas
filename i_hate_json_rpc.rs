use curl::easy::Easy;
use ethers::providers::{Http, Middleware, Provider};
use ethers::signers::{LocalWallet, Signer};
use ethers::types::transaction::eip2718::TypedTransaction;
use ethers::types::{
    Address, Bytes, Eip1559TransactionRequest, Eip2930TransactionRequest, TransactionRequest,
    TxHash, H160, U256, U64,
};
use std::io::Read;
use std::str::FromStr;
use std::thread;
use std::time::Duration;

// const RPC_URL: &str = "https://devnet.neonevm.org/";
// const RPC_URL: &str = "https://proxy.devnet.neonlabs.org/solana";
const RPC_URL: &str = "https://proxy.devnet.neonlabs.org/ethereum";
// const RPC_URL: &str = "https://neon-mainnet.everstake.one";
// const RPC_URL: &str = "https://virginia.rpc.blxrbdn.com";

#[tokio::main]
async fn main() {
    println!("This is peak developer performance");
    let pk = "5da86377230463d7979cc45f985f13ed600ce572534e45f9a1240ae7fb08da5f";
    let wallet = LocalWallet::from_str(pk).unwrap();
    assert_eq!(
        wallet.address(),
        Address::from_str("0xBEEf734581018284bdBa6144750206bfA41edf7D").unwrap()
    );
    let provider = Provider::<Http>::try_from(RPC_URL).unwrap();
    let gas_price: u128 = 25000000000000000;
    let mut nonce = provider
        .get_transaction_count(wallet.address(), None)
        .await
        .unwrap();
    // let mut nonce = U256::from(10000);
    loop {
        let mut tx_req = TransactionRequest::new();
        tx_req = tx_req.from(wallet.address());
        tx_req = tx_req.to(wallet.address());
        // tx_req = tx_req.value(U256::zero());
        tx_req = tx_req.value(U256::from(1));
        tx_req = tx_req.gas(U256::from(21000));
        tx_req = tx_req.gas_price(U256::from(gas_price));
        tx_req = tx_req.chain_id(U64::from(245022926));
        tx_req = tx_req.data(Bytes::from_str("").unwrap());
        tx_req = tx_req.nonce(nonce + 1);
        dbg!(&tx_req);
        let tx = TypedTransaction::Legacy(tx_req.clone());
        let signature = wallet.sign_transaction(&tx).await.unwrap();
        let rlp_signed = tx_req.rlp_signed(&signature);
        dbg!(&rlp_signed);
        // let ret = provider
        //     .send_raw_transaction(rlp_signed.clone())
        //     .await
        //     .unwrap()
        //     .confirmations(1)
        //     .await
        //     .unwrap();
        // dbg!(&ret);

        nonce += U256::from(1);
        println!("nonce: {}", nonce);

        let data = format!("{{\"jsonrpc\": \"2.0\", \"method\": \"eth_sendRawTransaction\", \"id\": {}, \"params\": [\"{}\"]}}", 1, rlp_signed);
        dbg!(&data);
        let mut data = data.as_bytes();

        let mut easy = Easy::new();
        easy.url(RPC_URL).unwrap();
        easy.post(true).unwrap();
        easy.post_field_size(data.len() as u64).unwrap();
        let mut transfer = easy.transfer();
        let mut res = data.clone();
        transfer
            .read_function(|buf| Ok(data.read(buf).unwrap_or(0)))
            .unwrap();
        transfer.perform().unwrap();

        // dbg!(data);

        thread::sleep(Duration::from_secs(20));
    }
}

