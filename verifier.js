const util = require('util')
const exec = util.promisify(require('child_process').exec)


const contractName = "TeenDoge"
const contractAddress = "0xFF9fd7146F7dF7398DCed770ba7fCA784b9e59a0"
const network = "bscTest"

const verify = async (_contractName, _contractAddress, _network) => {
    console.log("\nVerifying ...")
    console.log('Contract:', _contractName)
    console.log('Address:', _contractAddress)
    console.log('Network:', _network)

    const { stdout, stderr } = await exec(`truffle run verify ${_contractName}@${_contractAddress} --network ${_network}`)
    if(stderr != null) {
        console.log(stdout)
    } else {
        console.log('stderr:', stderr)
    }
}

verify(contractName, contractAddress, network)