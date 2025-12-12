const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CollateralizedLoan", function () {
  let collateralizedLoan;
  let borrower, lender;

  beforeEach(async function () {
    [borrower, lender] = await ethers.getSigners();

    const CollateralizedLoan = await ethers.getContractFactory("CollateralizedLoan");
    collateralizedLoan = await CollateralizedLoan.deploy();
    await collateralizedLoan.waitForDeployment(); // <-- ethers v6
  });

  it("deploys with a valid address", async function () {
    const address = await collateralizedLoan.getAddress(); // <-- ethers v6
    expect(address).to.properAddress;
  });

  it("allows borrower to request, lender to fund, and borrower to repay a loan", async function () {
    const collateralAmount = ethers.parseEther("1");
    const interestRate = 10;
    const duration = 24 * 60 * 60;

    // Borrower requests loan
    await collateralizedLoan
      .connect(borrower)
      .depositCollateralAndRequestLoan(interestRate, duration, {
        value: collateralAmount,
      });

    const loanId = 0;

    let loan = await collateralizedLoan.loans(loanId);
    expect(loan.borrower).to.equal(borrower.address);
    expect(loan.collateralAmount).to.equal(collateralAmount);
    expect(loan.isFunded).to.equal(false);

    // Lender funds the loan
    const loanAmount = loan.loanAmount;

    await collateralizedLoan
      .connect(lender)
      .fundLoan(loanId, { value: loanAmount });

    loan = await collateralizedLoan.loans(loanId);
    expect(loan.isFunded).to.equal(true);
    expect(loan.lender).to.equal(lender.address);

    // Borrower repays full amount
    const interest = (loanAmount * BigInt(interestRate)) / BigInt(100);
    const totalOwed = loanAmount + interest;

    await collateralizedLoan
      .connect(borrower)
      .repayLoan(loanId, { value: totalOwed });

    loan = await collateralizedLoan.loans(loanId);
    expect(loan.isRepaid).to.equal(true);
  });
});