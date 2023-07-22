from web3 import Web3

# Replace the following values with your own Ethereum node URL and private key
# Never share your private key publicly or commit it to a repository
eth_node_url = "https://devnet.neonevm.org"
private_key = "deb22b9a7834b4f526db5fc8dd820e182775d457013285f98c494bd28e9f362c"

# Replace these with the sender and receiver addresses
sender_address = "0xa6A0BE4d4dE1874f56797a21970E8C66b9c76805"
receiver_address = "0xa6A0BE4d4dE1874f56797a21970E8C66b9c76805"

def send_transaction(web3, nonce):
    if not web3.is_connected():
        print("Error: Could not connect to Ethereum node.")
        return
    

    print(web3.eth.gas_price)
    # Create the transaction
    transaction = {
        "to": receiver_address,
        "value": web3.to_wei(0.1, "ether"),  # 0.1 Ether, you can adjust the value as needed
        "gas": 60000,  # Standard gas limit for a simple transfer
        "gasPrice": int(web3.eth.gas_price * 2),
        "nonce": nonce,
    }

    # Sign the transaction
    signed_transaction = web3.eth.account.sign_transaction(transaction, private_key)

    # Send the transaction
    tx_hash = web3.eth.send_raw_transaction(signed_transaction.rawTransaction)

    print(f"Transaction sent. Transaction Hash: {web3.to_hex(tx_hash)}")


if __name__ == "__main__":
    web3 = Web3(Web3.HTTPProvider(eth_node_url))
    current_nonce = web3.eth.get_transaction_count(sender_address)+1
    while True:
        send_transaction(web3, current_nonce)
        current_nonce += 1
