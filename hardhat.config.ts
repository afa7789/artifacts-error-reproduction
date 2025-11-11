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
    version: '0.8.20',
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

