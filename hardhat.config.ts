import type { HardhatUserConfig } from 'hardhat/config';

/**
 * Hardhat 3 Configuration
 * 
 * Key settings for Solidity tests:
 * - paths.tests.solidity: Where Solidity test files are located
 * - test.solidity.ffi: Enables FFI for vm.getCode() and other cheatcodes
 * - test.solidity.fsPermissions: Allows reading artifacts directory
 * 
 * NOTE: Even though fsPermissions allows reading artifacts/contracts/,
 * Hardhat's EDR doesn't load these artifacts into memory. The artifacts
 * exist on disk but are not available to vm.getCode().
 */
const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.22',
    // Generate artifacts from npm dependencies
    // This allows vm.getCode() to find contracts from packages like @openzeppelin/contracts
    // See: https://hardhat.org/docs/guides/configuring-the-compiler#generating-artifacts-from-npm-dependencies
    npmFilesToBuild: [
      "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol",
      "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol",
      "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol",
      "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol",
      "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol",
    ],
  },
  paths: {
    // Tell Hardhat where Solidity test files are located
    tests: {
      solidity: "./test/solidity"
    }
  },
  test: {
    solidity: {
      // Enable FFI for vm.getCode() and other forge-std cheatcodes
      ffi: true,
      fsPermissions: {
        // Allow reading artifact files
        readFile: [
          './hardhat.config.ts',
          './artifacts/**/*.json',
        ],
        // Allow reading artifact directories
        readDirectory: [
          './artifacts',
          './artifacts/contracts',
        ],
      },
    },
  },
};

export default config;

