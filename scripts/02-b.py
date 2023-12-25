def compute_withdrawal(
    current_balance: int, out_stk: int, current_total_shares: int
) -> int:
    # Compute the withdrawal amount
    withdrawal = current_balance * out_stk // current_total_shares
    # Return the withdrawal amount
    return withdrawal


def compute_mint(current_balance: int, in_stk: int, current_total_shares: int) -> int:
    # Compute the mint amount
    mint = current_total_shares * in_stk // current_balance
    # Return the mint amount
    return mint


target_minimal_balance = 1

# Initial state
target_total_balance = int(40 * 1e18)
target_total_shares = int(30 * 1e18)
attacker_balance_ether = int(1e18)
attacker_balance = 0
attacker_stk = attacker_balance
# Attacker deposit
target_total_balance += attacker_balance_ether
attack_balance = attacker_balance_ether
attacker_stk = attack_balance
attacker_balance_ether = 0

# Reentrancy exploited and gathered some ETH
attacker_balance_ether = target_total_balance - target_minimal_balance
target_total_balance = target_minimal_balance


attacker_most_shares = compute_mint(
    target_total_balance,
    attacker_stk,
    target_total_shares,
)
target_total_shares += attacker_most_shares

target_total_balance += attacker_balance_ether
attacker_balance_ether = 0
print(f"Attacker most shares: {attacker_most_shares}")

attacker_most_profit = compute_withdrawal(
    target_total_balance, attacker_most_shares, target_total_shares
)

print(f"Attacker most profit: {attacker_most_profit}")
