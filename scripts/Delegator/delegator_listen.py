from web3 import Web3, IPCProvider
import time
from threading import Thread

# instantiate Web3 instance
w3 = Web3(Web3.HTTPProvider('http://127.0.0.1:7545'))

print(w3.is_connected())

contract_address = '0xAD9a0493d7dd94246e40C46D259D915b6e4Be41b'#合约部署地址

contract_abi = [                                            
    {
        "inputs": [
            {
                "internalType": "string",
                "name": "txid",
                "type": "string"
            }
        ],
        "name": "CheckCTI",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "anonymous": False,
        "inputs": [
            {
                "indexed": False,
                "internalType": "address",
                "name": "delegator_address",
                "type": "address"
            },
            {
                "indexed": False,
                "internalType": "string",
                "name": "txid",
                "type": "string"
            },
            {
                "indexed": False,
                "internalType": "uint256",
                "name": "pay",
                "type": "uint256"
            },
            {
                "indexed": False,
                "internalType": "string",
                "name": "pubkey",
                "type": "string"
            }
        ],
        "name": "ConsumerAssignmentComing",
        "type": "event"
    },
    {
        "inputs": [
            {
                "internalType": "string",
                "name": "tid",
                "type": "string"
            },
            {
                "internalType": "string",
                "name": "txid",
                "type": "string"
            },
            {
                "internalType": "address",
                "name": "addr",
                "type": "address"
            },
            {
                "internalType": "string",
                "name": "pubkey",
                "type": "string"
            }
        ],
        "name": "ConsumerSelectDelegator",
        "outputs": [],
        "stateMutability": "payable",
        "type": "function"
    },
    {
        "anonymous": False,
        "inputs": [
            {
                "indexed": False,
                "internalType": "address",
                "name": "consumer",
                "type": "address"
            },
            {
                "indexed": False,
                "internalType": "string",
                "name": "ipfshash",
                "type": "string"
            },
            {
                "indexed": False,
                "internalType": "string",
                "name": "txid",
                "type": "string"
            }
        ],
        "name": "IPFSHashComing",
        "type": "event"
    },
    {
        "anonymous": False,
        "inputs": [
            {
                "indexed": False,
                "internalType": "address[]",
                "name": "addresses",
                "type": "address[]"
            },
            {
                "indexed": False,
                "internalType": "address",
                "name": "producer",
                "type": "address"
            },
            {
                "indexed": False,
                "internalType": "string",
                "name": "tid",
                "type": "string"
            },
            {
                "indexed": False,
                "internalType": "string",
                "name": "ipfshash",
                "type": "string"
            }
        ],
        "name": "ProducerAssignmentComing",
        "type": "event"
    },
    {
        "inputs": [
            {
                "internalType": "string",
                "name": "tid",
                "type": "string"
            },
            {
                "internalType": "address[]",
                "name": "delegators_address",
                "type": "address[]"
            },
            {
                "internalType": "uint256",
                "name": "price",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "producer_price",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "delegator_price",
                "type": "uint256"
            },
            {
                "internalType": "string",
                "name": "ipfsHash",
                "type": "string"
            }
        ],
        "name": "ProducerSelectDelegator",
        "outputs": [
            {
                "internalType": "bool",
                "name": "",
                "type": "bool"
            }
        ],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "string",
                "name": "ipfshash",
                "type": "string"
            },
            {
                "internalType": "address",
                "name": "consumer",
                "type": "address"
            },
            {
                "internalType": "string",
                "name": "txid",
                "type": "string"
            }
        ],
        "name": "UploadCTI",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "string",
                "name": "tid",
                "type": "string"
            },
            {
                "internalType": "bool",
                "name": "opt",
                "type": "bool"
            }
        ],
        "name": "VerifyAssignment",
        "outputs": [
            {
                "internalType": "bool",
                "name": "",
                "type": "bool"
            }
        ],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "string",
                "name": "tid",
                "type": "string"
            }
        ],
        "name": "GetAssignmentVerified",
        "outputs": [
            {
                "internalType": "address[]",
                "name": "",
                "type": "address[]"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "string",
                "name": "",
                "type": "string"
            }
        ],
        "name": "tx_list",
        "outputs": [
            {
                "internalType": "string",
                "name": "tid",
                "type": "string"
            },
            {
                "internalType": "string",
                "name": "txid",
                "type": "string"
            },
            {
                "internalType": "address",
                "name": "producer",
                "type": "address"
            },
            {
                "internalType": "address",
                "name": "delegator",
                "type": "address"
            },
            {
                "internalType": "address",
                "name": "consumer",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "price",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "producer_price",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "delegator_price",
                "type": "uint256"
            },
            {
                "internalType": "int256",
                "name": "status",
                "type": "int256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    }
]

my_contract = w3.eth.contract(address=contract_address, abi=contract_abi)


def handle_producer_event(event):
    for address in event['args']['addresses']:
        if address == "0x2c1a55309948f72b611884CcF538d5320b8d6Ff5":
            print(event)


def handle_consumer_event(event):
    addr = event['args']['addr']
    if addr == "0xF6118c1806Bc5B4d4e25D10A16C8553d0c11Af51":
        print(event)


def log_loop1(event_filter, poll_interval):
    while True:
        for event in event_filter.get_new_entries():
            handle_producer_event(event)
        time.sleep(poll_interval)


def log_loop2(event_filter, poll_interval):
    while True:
        for event in event_filter.get_new_entries():
            handle_consumer_event(event)
        time.sleep(poll_interval)

def listen_producer():
    event_filter = (my_contract.events.
                    ProducerAssignmentComing().
                    create_filter(from_block="latest",
                                  topics="0xf52fcbc5cb218bae54b5dee4a14189098257cb16cc5649f3daeff8c73a56104d"))
    # block_filter = w3.eth.filter('latest')
    log_loop1(event_filter, 2)


def listen_consumer():
    event_filter = (my_contract.events.
                    ConsumerAssignmentComing().
                    create_filter(from_block="latest",
                                  topics="0x1a1587044d0ef231ec01eb255f9ed91998f8da4a5cdbaddf41223706f8b71258"))
    # block_filter = w3.eth.filter('latest')
    log_loop2(event_filter, 2)


if __name__ == '__main__':
    listen_producer()
