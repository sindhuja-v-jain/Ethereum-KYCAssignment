pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

contract KYC {

  
    address admin;
    
    // Struct for a customer
    struct Customer {
        string userName;   //unique
        string data_hash;  //unique
        uint8 userRating;
        uint8 upvotes;
        address bank;
        bytes password;
    }

   // Struct for a Bank
    struct Bank {
        address ethAddress;   //unique  
        string bankName;
        string regNumber;       //unique   
        uint8 upvotes;
        uint8 bankRating;
        uint kyc_count;
   }


   // Struct for a KYC Request
    struct KYCRequest {
        string userName;     
        string data_hash;  //unique
        address bank;
        bool isAllowed;
    }

    // a variable to keep track of the count of the number of banks 
    uint8 public bankCount = 0;

    /*
    Mapping a customer's username to the Customer struct
    We also keep an array of all keys of the mapping to be able to loop through them when required.
     */
    mapping(string => Customer) customers;
   // string[] customerNames;
   // string[] verifiedCustomerNamesList;

    /*
    Mapping a bank's address to the Bank Struct
    We also keep an array of all keys of the mapping to be able to loop through them when required.
     */
    mapping(address => Bank) banks;
    //address[] bankAddresses;

    /*
    Mapping a customer's Data Hash to KYC request captured for that customer.
    This mapping is used to keep track of every kycRequest initiated for every customer by a bank.
     */
    mapping(string => KYCRequest) kycRequests;
    //string[] customerDataList;

    /*
    Mapping a customer's user name with a bank's address
    This mapping is used to keep track of every upvote given by a bank to a customer
     */
    mapping(string => mapping(address => uint256)) upvotes;
    
    /*
    Mapping a  bank's address with other bank's address
    This mapping is used to keep track of every upvote given by a bank to other bank
     */
    mapping(address => mapping(address => uint256)) upvotesBank;
    
    /*
    Mapping a  username to the same username 
    This mapping is used to keep track of the verifiedCustomerNamesList 
     */
    mapping(string => string) verifiedCustomerNamesList;
 
    /**
     * Constructor of the contract.
     * We save the contract's admin as the account which deployed this contract.
     */
    constructor() public {
        admin = msg.sender;
    }

    /**
     * Record a new KYC request on behalf of a customer
     * The sender of message call is the bank itself
     * @param  {string} _userName The name of the customer for whom KYC is to be done
     * @param  {address} _bankEthAddress The ethAddress of the bank issuing this request
     * @return {bool}        True if this function execution was successful
     */
    function addKycRequest(string memory _userName, string memory _customerData) public returns (uint8) {
        // Check that the user's KYC has not been done before, the Bank is a valid bank and it is allowed to perform KYC.
        require(kycRequests[_customerData].bank == address(0), "This user already has a KYC request with same data in process.");
        //bytes memory uname = new bytes(bytes(_userName));
        // Save the timestamp for this KYC request.
        kycRequests[_customerData].data_hash = _customerData;
        kycRequests[_customerData].userName = _userName;
        kycRequests[_customerData].bank = msg.sender;
            if(banks[msg.sender].bankRating <= 50 ){ //bankRating was multiplied with 100 as suggested in the online assignment session as solidity doesnt support floating point
                kycRequests[_customerData].isAllowed = false;
           } else {
                 kycRequests[_customerData].isAllowed = true;
          }
       // customerDataList.push(_customerData);
       // pushing the data into mapping since it is required for getBankInitiatedKYCRequests function .
       bankKYCRequests[msg.sender].push(_customerData);
        return 1;
    }

    /**
     * Add a new customer
     * @param {string} _userName Name of the customer to be added
     * @param {string} _hash Hash of the customer's ID submitted for KYC
     */
    function addCustomer(string memory _userName, string memory _customerData) public returns (uint8) {
        require(customers[_userName].bank == address(0), "This customer is already present, please call modifyCustomer to edit the customer data");
        require(banks[msg.sender].bankRating > 50, "The Bank is not permissioned  to add the customer because of its low rating");
        customers[_userName].userName = _userName;
        customers[_userName].data_hash = _customerData;
        customers[_userName].bank = msg.sender;
        customers[_userName].upvotes = 0;
        customers[_userName].userRating = 0;
        //customerNames.push(_userName);
        return 1;
    }
     
     
    /**
     * Remove KYC request
     * @param  {string} _userName Name of the customer
     * @return {uint8} 1 indicates success, otherwise error msg is prompted
     */
    function removeKYCRequest(string memory _userName, string memory _customerData)  public returns (uint8) {
        //check if customerData exists in the kycRequests
        require(stringsEquals(kycRequests[_customerData].data_hash, _customerData) , "The user Data doesnt exist in kycRequests");
        require(stringsEquals(kycRequests[_customerData].userName, _userName), "The userName doesnt exist in kycRequests");
                 delete kycRequests[_customerData];
                 return 1;
        }
        
    // modifier to check the existence of userName
    modifier isUsernameExists(string memory _userName) {
        require(stringsEquals(customers[_userName].userName, _userName), "The userName doesnt exist");
        _;
    }
    
    /**
     * Remove customer information
     * @param  {string} _userName Name of the customer
     * @return {uint8} 1 indicates success, otherwise error msg is prompted
     */
    function removeCustomer(string memory _userName) isUsernameExists(_userName) public returns (uint8) {
        delete customers[_userName];
            return 1;
    }
        
    // modifier to check whether the password is set for the customerData or the incoming password should be equal to "0" 
    modifier isPasswordSet(string memory _userName, bytes memory _password) {
        bytes memory c = "0";
        // The hashes of the incoming password and "0" are compared using keccak256
        require(setCustomerPassword(_userName, _password) == true || (keccak256(_password) == keccak256(c)),"Please type the correct password to view customer details"); 
        _;
    }
    
    /**
     * View customer information
     * @param  {public} _userName 
     * @param  {public} _password
     * @return {string} the hash of the customer data in form of a string
     */
    function viewCustomer(string memory _userName, bytes memory _password) isUsernameExists(_userName) isPasswordSet(_userName, _password) public returns (string memory) {
               
            return customers[_userName].data_hash;
        }
    
    /**
     * Set password for the customers
     * @param  {public} _userName Name of the customer
     * @param  {public} _password password for the customer
     * @return {bool}  true indicates passwordSet, false indicates password not set
     */
    function setCustomerPassword(string memory _userName, bytes memory _password) isUsernameExists(_userName) public  returns (bool) {
        if(customers[_userName].password.length == 0 || keccak256(customers[_userName].password) == keccak256( _password)) 
            {
              customers[_userName].password = _password;
              return true;
            } 
        return false;
    }
            

    /**
     * Add a new upvote from a bank
     * @param {public} _userName Name of the customer to be upvoted
     * @return {uint8}  on failure if userName doesnt exist error message is thrown, 1 indicates success
     */
    function UpvoteCustomer(string memory _userName) isUsernameExists(_userName) public returns (uint8) {
        require(upvotes[_userName][msg.sender] == 0 , "The Bank has already voted");
        customers[_userName].upvotes++;
        upvotes[_userName][msg.sender] = 1; //setting  the upVote to 1 given by Bank to this customer in the mapping upVotes
        customers[_userName].userRating= (customers[_userName].upvotes * 100)/bankCount;
                    if((customers[_userName].userRating) > 50) 
                    {   // the calculated rating is multiplied with 100 was suggested in the assignment online session as solidity doesnt support floating point
                        verifiedCustomerNamesList[_userName] = _userName;
                    }
            return 1;
        }
        
    /**
     * Edit customer information
     * @param  {public} _userName Name of the customer
     * @param  {public} _password password set for the customer data
     * @param  {public} _hash New hash of the updated ID provided by the customer
     * @return {uint8}  an error message is thrown if username or password doesnt exists on failure, 1 indicates success
     */
    function modifyCustomer(string memory _userName, bytes memory _password, string memory _newcustomerData) isUsernameExists(_userName) isPasswordSet(_userName,_password) public returns (uint8) {
           customers[_userName].data_hash = _newcustomerData;
           customers[_userName].bank = msg.sender; //updating the banks address since it is modifying the customer data
              if(stringsEquals(verifiedCustomerNamesList[_userName],_userName))
                     {
                        customers[_userName].upvotes = 0;
                        customers[_userName].userRating = 0;
                        delete verifiedCustomerNamesList[_userName];
                     }
        return 1;
    }
    
    /**
     * get Customer Rating
     * @param  {public} _userName Name of the customer
     * @return {uint}  userRating is returned
     * if the username doesnt match error message is thrown
     */
    
    function getCustomerRating(string memory _userName) isUsernameExists(_userName) public view returns(uint8) {
               return customers[_userName].userRating;
    }
    
    
     // only admin has the privilege to add the Bank
     modifier onlyAdmin() {
        require( admin == msg.sender ,"The admin can only add/remove the Bank");
        _;
    }
    
    // modifier to check bank address exists
    modifier isBankAddressExists(address _ethAddress) {
        require(banks[_ethAddress].ethAddress == _ethAddress, "The Bank Address doesnt exists");
        _;
    }
    
    
    /**
     * Add bank - only admin has the access to add the bank
     * 
     * @param  {string} _bankName 
     * @param  {address} _ethAddress 
     * @param  {string} _regNumber
     * @param  {uint} upvotes;
     * @param  {uint8} bankRating;
     * @param  {uint} kyc_count;
     * @return {uint} 1  if this function execution was successful
     */
     
     function addBank(string memory _bankName, address _ethAddress, string memory _regNumber) public onlyAdmin returns(uint8) {
        //check bank already exists
        require(banks[_ethAddress].ethAddress == address(0), "The Bank is already present");
         banks[_ethAddress].bankName = _bankName;
         banks[_ethAddress].ethAddress = _ethAddress;
         banks[_ethAddress].regNumber = _regNumber;
         banks[_ethAddress].upvotes = 0;
         banks[_ethAddress].bankRating = 0;
         banks[_ethAddress].kyc_count = 0;
         bankCount++;
       //bankAddresses.push(_ethAddress);
         return 1;
         
     }
     /**
     * Remove Bank
     * @param  {address}  Banks unique Adress
     * @return {uint8} A 0 indicates failure, 1 indicates success
     */
    function removeBank(address _ethAddress) public onlyAdmin isBankAddressExists(_ethAddress) returns (uint8) {
         delete banks[_ethAddress];
         bankCount--;
         return 1;
     }
     
    /**
     * get the kycRequests initiated by a Bank
     * @param  {public} uniqueBankAdress
     * @return   list of kycRequests is returned
     * @return error message is prompted if bankAdrress is not found
     */
    
    //mapping a bank address to the  string array of specificBankKYCRequestsList
     mapping(address => string[]) bankKYCRequests;
    
   function getBankInitiatedKYCRequests(address _ethAddress)  public view returns(string[] memory) {
       return bankKYCRequests[_ethAddress];
   }
   
    /**
     * Add a new upvote from a bank to a bank
     * update the bankrating
     * @param {public} _eththAddress as the input parameter for which vote is casted
     * @return {uint8}  on failure if bankaddress is not found error message is thrown, 1 indicates success
     */
    function upvoteBank(address _ethAddress) isBankAddressExists(_ethAddress) public returns (uint8) {
              require(upvotesBank[_ethAddress][msg.sender] == 0 , "The Bank has already voted");
              require(banks[_ethAddress].ethAddress != msg.sender, "A Bank cannot upvote its own Bank");
              banks[_ethAddress].upvotes++;
              upvotesBank[_ethAddress][msg.sender] = 1;    //setting the value to one since the bank has voted to this bank
              banks[_ethAddress].bankRating = (banks[_ethAddress].upvotes * 100)/ bankCount;
              return 1;
        }
        
        
    /**
     * get Bank Rating
     * @param  {public} _ethAddress of the bank
     * @return {uint}  bankRating is returned
     * @return error message is thrown if bank address not found
     */
    
    function getBankRating(address _ethAddress) isBankAddressExists(_ethAddress) public view returns(uint8) {
              return banks[_ethAddress].bankRating;
        }
    
    /**
     * fetch the bank details which made the last changes to the customer data
     * @param  {public} _userName
     * @return {uint}  bankAddress is returned
     * @return error message is thrown if userName doesnt exists
     */
     
     function getAccessHistory(string memory _userName) isUsernameExists(_userName) public view returns(address) {
           return customers[_userName].bank; //fetching the bank address from customers mapping since the bank address was updated in the modifyCustomer function
         }
    
    /**
     * fetch the bank details 
     * @param  {public} _ethAddress of the bank
     * @return Bank struct is returned
     * @return error message is thrown if bankAddress doesnt exists
     */
     
      function getBankDetails(address _ethAddress) isBankAddressExists(_ethAddress) public view returns(Bank memory) {
            return banks[_ethAddress];
        }
    
        
// if you are using string, you can use the following function to compare two strings
// function to compare two string value
// This is an internal fucntion to compare string values
// @Params - String a and String b are passed as Parameters
// @return - This function returns true if strings are matched and false if the strings are not matching
    function stringsEquals(string storage _a, string memory _b) internal view returns (bool) {
        bytes storage a = bytes(_a);
        bytes memory b = bytes(_b); 
        if (a.length != b.length)
            return false;
        // @todo unroll this loop
        for (uint i = 0; i < a.length; i ++)
        {
            if (a[i] != b[i])
                return false;
        }
        return true;
    }

}