// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract CloneFactory {
    event CloneCreationLog(address indexed cloneAddress, address indexed cloneTarget);
    event CloneInitializationSuccessLog(bool status, address indexed cloneAddress, address indexed cloneTarget);

    function _createClone(address _target, bytes memory _data) internal returns (address proxy) {
        bytes20 targetAddressBytes = bytes20(_target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetAddressBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            proxy := create(0, clone, 0x37)
        }
        require(proxy != 0x0000000000000000000000000000000000000000, 'CloneCreationFailed');
        emit CloneCreationLog(proxy, _target);

        if (_data.length > 0) {
            (bool success, ) = proxy.call(_data);
            if (success == true) {
                emit CloneInitializationSuccessLog(true, proxy, _target);
            } else {
                emit CloneInitializationSuccessLog(false, proxy, _target);
                revert('reverted during initialization');
            }
        }
    }

    function _isClone(address target, address query) internal view returns (bool result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
            mstore(add(clone, 0xa), targetBytes)
            mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(eq(mload(clone), mload(other)), eq(mload(add(clone, 0xd)), mload(add(other, 0xd))))
        }
    }
}
