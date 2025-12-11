
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Collateralized Loan Contract
contract CollateralizedLoan {
    // Define the structure of a loan
    struct Loan {
        address payable borrower;
        address payable lender;
        uint256 collateralAmount;
        uint256 loanAmount;        // in wei
        uint256 interestRate;      // e.g. 10 = 10%
        uint256 dueDate;           // timestamp when loan is due
        bool isFunded;
        bool isRepaid;
        bool collateralClaimed;
    }

    // Create a mapping to manage the loans
    mapping(uint256 => Loan) public loans;
    uint256 public nextLoanId;

    // Events for loan lifecycle
    event LoanRequested(
        uint256 indexed loanId,
        address indexed borrower,
        uint256 collateralAmount,
        uint256 loanAmount,
        uint256 interestRate,
        uint256 dueDate
    );

    event LoanFunded(
        uint256 indexed loanId,
        address indexed lender,
        uint256 amount
    );

    event LoanRepaid(
        uint256 indexed loanId,
        address indexed borrower,
        uint256 amount
    );

    event CollateralClaimed(
        uint256 indexed loanId,
        address indexed lender,
        uint256 amount
    );

    // ===== MODIFIERS =====

    // Check that a loan exists
    modifier loanExists(uint256 _loanId) {
        require(_loanId < nextLoanId, "Loan does not exist");
        _;
    }

    // Ensure loan is not already funded
    modifier notFunded(uint256 _loanId) {
        require(!loans[_loanId].isFunded, "Loan already funded");
        _;
    }

    modifier onlyBorrower(uint256 _loanId) {
        require(msg.sender == loans[_loanId].borrower, "Not borrower");
        _;
    }

    modifier onlyLender(uint256 _loanId) {
        require(msg.sender == loans[_loanId].lender, "Not lender");
        _;
    }

    // ===== CORE FUNCTIONS =====

    // Function to deposit collateral and request a loan
    // In this project design: loanAmount = collateralAmount (1:1)
    function depositCollateralAndRequestLoan(
        uint256 _interestRate,
        uint256 _duration
    ) external payable {
        require(msg.value > 0, "Collateral must be > 0");
        require(_duration > 0, "Duration must be > 0");

        uint256 loanId = nextLoanId;
        nextLoanId++;

        uint256 collateralAmount = msg.value;
        uint256 loanAmount = collateralAmount; // 1:1 for this project

        uint256 dueDate = block.timestamp + _duration;

        loans[loanId] = Loan({
            borrower: payable(msg.sender),
            lender: payable(address(0)),
            collateralAmount: collateralAmount,
            loanAmount: loanAmount,
            interestRate: _interestRate,
            dueDate: dueDate,
            isFunded: false,
            isRepaid: false,
            collateralClaimed: false
        });

        emit LoanRequested(
            loanId,
            msg.sender,
            collateralAmount,
            loanAmount,
            _interestRate,
            dueDate
        );
    }

    // Lender funds the loan
    function fundLoan(uint256 _loanId)
        external
        payable
        loanExists(_loanId)
        notFunded(_loanId)
    {
        Loan storage loan = loans[_loanId];

        require(loan.borrower != address(0), "Invalid loan");
        require(msg.value == loan.loanAmount, "Incorrect funding amount");

        loan.lender = payable(msg.sender);
        loan.isFunded = true;

        // Transfer loan amount to borrower
        loan.borrower.transfer(loan.loanAmount);

        emit LoanFunded(_loanId, msg.sender, msg.value);
    }

    // Borrower repays the loan with interest before due date
    function repayLoan(uint256 _loanId)
        external
        payable
        loanExists(_loanId)
        onlyBorrower(_loanId)
    {
        Loan storage loan = loans[_loanId];

        require(loan.isFunded, "Loan not funded");
        require(!loan.isRepaid, "Loan already repaid");
        require(block.timestamp <= loan.dueDate, "Loan is past due date");

        uint256 interest = (loan.loanAmount * loan.interestRate) / 100;
        uint256 totalOwed = loan.loanAmount + interest;

        require(msg.value == totalOwed, "Incorrect repayment amount");

        loan.isRepaid = true;

        // Pay lender principal + interest
        loan.lender.transfer(totalOwed);

        // Return collateral to borrower
        uint256 collateral = loan.collateralAmount;
        loan.collateralAmount = 0; // clear before transfer to avoid issues
        loan.borrower.transfer(collateral);

        emit LoanRepaid(_loanId, msg.sender, msg.value);
    }

    // Lender claims collateral if loan is not repaid in time
    function claimCollateral(uint256 _loanId)
        external
        loanExists(_loanId)
        onlyLender(_loanId)
    {
        Loan storage loan = loans[_loanId];

        require(loan.isFunded, "Loan not funded");
        require(!loan.isRepaid, "Loan already repaid");
        require(!loan.collateralClaimed, "Collateral already claimed");
        require(block.timestamp > loan.dueDate, "Too early to claim collateral");

        loan.collateralClaimed = true;

        uint256 collateral = loan.collateralAmount;
        loan.collateralAmount = 0; // clear before transfer
        loan.lender.transfer(collateral);

        emit CollateralClaimed(_loanId, msg.sender, collateral);
    }
}