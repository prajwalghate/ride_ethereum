pragma solidity >= 0.4.22 <0.7.0;

contract CrowdRide {
    
    address public owner ;
    
    
    enum ProposalState {
        WAITING,
        ACCEPTED,
        RETREAT
    }
    
    
    
    enum rideState {
        ACCEPTING,
        LOCKED,
        SUCCESSFUL,
        FAILED
    }
    
    
    
    struct Proposal {
        address payable driver;
        uint rideId;
        ProposalState state;
        uint amount;
    }
    
    
    struct Ride {
        address payable rider;
        rideState state;
        string source ;
        string destination;
        uint proposalCount;
        mapping (uint => uint ) proposal;
        
    }
    
    
    Ride[] public rideList;
    Proposal[] public proposalList;

    mapping (address=>uint[]) public rideMap;
    mapping (address=>uint[]) public driverMap;
    
    
    constructor () public {
        owner = msg.sender;
        
    }


    function hasActiveRide(address rider) public view returns(bool) {
        uint validRides = rideMap[rider].length;
        if(validRides == 0) return false;
        Ride storage obj = rideList[rideMap[rider][validRides-1]];
        if(rideList[validRides-1].state == rideState.ACCEPTING) return true;
        if(rideList[validRides-1].state == rideState.LOCKED) return true;
        return false;
    }

    function getActiveRideId(address rider) public view returns(uint) {
        uint numRides = rideMap[rider].length;
        if(numRides == 0) return (2**64 - 1);
        uint lastRideId = rideMap[rider][numRides-1];
        if(rideList[lastRideId].state != rideState.ACCEPTING) return (2**64 - 1);
        return lastRideId;
    }



    
    function newRide (string memory _source ,string memory _destination ) public {
        if(hasActiveRide(msg.sender)) return;
        
        rideList.push(Ride(msg.sender,rideState.ACCEPTING,_source,_destination,0));
        rideMap[msg.sender].push(rideList.length-1);
        
    } 
    
    function newProposal(uint _rideId,uint _amount) public {
        if(rideList[_rideId].rider == address(0) || rideList[_rideId].state != rideState.ACCEPTING)
            return;
        proposalList.push(Proposal(msg.sender,_rideId, ProposalState.WAITING,_amount));
        driverMap[msg.sender].push(proposalList.length-1);
        rideList[_rideId].proposalCount++;
        rideList[_rideId].proposal[rideList[_rideId].proposalCount-1]=proposalList.length-1;
        
        
    }

    

    function lockRide(uint rideId) public payable {
        //contract will send mone0y to msg.sender
        //states of proposals would be finalized, not accepted proposals would be reimbursed
        if(rideList[rideId].state == rideState.ACCEPTING)
        {
          rideList[rideId].state = rideState.LOCKED;
          for(uint i = 0; i < rideList[rideId].proposalCount; i++)
          {
            uint numI = rideList[rideId].proposal[i];
            if(proposalList[numI].state == ProposalState.ACCEPTED)
            {
            proposalList[numI].driver.transfer(proposalList[numI].amount); //Send to driver
            }
            else
            {
              proposalList[numI].state = ProposalState.RETREAT;
            }
          }
        }
        else
          return;
    }


   function acceptProposal(uint proposeId) public
    {
        uint rideId = getActiveRideId(msg.sender); 
        if(rideId == (2**64 - 1)) return;
        Proposal storage pObj = proposalList[proposeId];
        if(pObj.state != ProposalState.WAITING) return;

        Ride storage lObj = rideList[rideId];
        if(lObj.state != rideState.ACCEPTING) return;
        
        //if(lObj.collected + pObj.amount <= lObj.amount)
        //{
        //  rideList[rideId].collected += pObj.amount;
          proposalList[proposeId].state = ProposalState.ACCEPTED;
        //}
        
    }
    
    
    //Proposal
    function totalProposalsBy(address driver) public view returns(uint) {
        return driverMap[driver].length;
    }

     function getProposalAtPosFor(address driver, uint pos) public view returns(address, uint, ProposalState, uint) {
        Proposal storage prop = proposalList[driverMap[driver][pos]];
        return (prop.driver, prop.rideId, prop.state , prop.amount);
    }

    // Rider getter 

     function totalRidesBy(address borrower) public view returns(uint) {
        return rideMap[borrower].length;
    }

     function getRideDetailsByAddressPosition(address borrower, uint pos) public view returns(rideState, string memory ,string memory, uint) {
        Ride storage obj = rideList[rideMap[borrower][pos]];
        return (obj.state, obj.source, obj.destination, rideMap[borrower][pos]);
    }

     function getLastrideState(address borrower) public view returns(rideState) {
        uint rideLength = rideMap[borrower].length;
        if(rideLength == 0)
            return rideState.SUCCESSFUL;
        return rideList[rideMap[borrower][rideLength -1]].state;
    }

     function getLastRideDetails(address borrower) public view returns(rideState, string memory ,string memory, uint) {
        uint rideLength = rideMap[borrower].length;
        Ride storage obj = rideList[rideMap[borrower][rideLength -1]];
        return (obj.state, obj.source, obj.destination, obj.proposalCount);
    }

     function getProposalDetailsByRideIdPosition(uint rideId, uint numI) public view returns(address, uint, ProposalState, uint,uint) {
        Proposal storage obj = proposalList[rideList[rideId].proposal[numI]];
        return (obj.driver, obj.rideId, obj.state , obj.amount, rideList[rideId].proposal[numI]);
    }

     function numTotalRides() public view returns(uint) {
        return rideList.length;
    }
    
    
    
    
}