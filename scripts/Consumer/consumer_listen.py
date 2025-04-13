from web3 import Web3, IPCProvider
import time
from threading import Thread

# instantiate Web3 instance
w3 = Web3(Web3.HTTPProvider('http://127.0.0.1:8545'))

print(w3.is_connected())

contract_address = '0xAD9a0493d7dd94246e40C46D259D915b6e4Be41b'
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


def handle_event(event):
    addr = event['args']['consumer']
    if addr == "0x1726A280A287DbE386A4b534EAC840F7cE8A1095":
        print(event)


def log_loop(event_filter, poll_interval):
    while True:
        for event in event_filter.get_new_entries():
            handle_event(event)
        time.sleep(poll_interval)


# ["0xb31ba45913946147ef22145e394e8cd92dc91d83",["0xb31ba45913946147ef22145e394e8cd92dc91d84"]
def listen():
    event_filter = (my_contract.events.
                    IPFSHashComing().
                    create_filter(from_block="latest",
                                  topics="0x696776fbada6026b2cc4883473b601f70eed8609668c456c07681055dca814f0"))
    # block_filter = w3.eth.filter('latest')
    log_loop(event_filter, 2)


if __name__ == '__main__':
    listen()
