import numpy as np
import matplotlib.pyplot as plt
from black_scholes import black_scholes
from provider_payoff import liquidity_provider_payoff_v3
from save_csv import save_to_csv

# Set the parameters
NUM_SIMULATIONS = 10
NUM_DAYS = 365
LAST_PRICE = 1957  # This should be the current price of ETH
VOLATILITY = 0.4  # This should be the historical VOLATILITY of ETH
EXPECTED_RETURN = 0.00  # This should be the expected return of ETH
NUM_ETH = 1  # Amount of ETH in collateral
NUM_OPTIONS = 1  # Number of options bought
STRIKE_PRICE = LAST_PRICE  # 30%+ of the starting price
MATURITY = 365 / 365  # Maturity of the the option
INTEREST_RATE = 0.04
SUPPLIED_PRICE = 1957
SUPPLIED_AMOUNT = 1  # Amount of currency supplied by the liquidity provider

# Create an empty matrix to hold the end price data
all_simulated_price = np.zeros((NUM_SIMULATIONS, NUM_DAYS))

# Create an empty matrix to hold the provider payoff data
all_simulated_provider_payoff = np.zeros((NUM_SIMULATIONS, NUM_DAYS))

# Create an empty matrix to hold the portfolio value data
all_simulated_provider_payoff_with_options = np.zeros((NUM_SIMULATIONS, NUM_DAYS))

# Create an empty matrix to hold the options value data
all_simulated_options_value = np.zeros((NUM_SIMULATIONS, NUM_DAYS))

# Run the Monte Carlo simulation
for x in range(NUM_SIMULATIONS):
    # Calculate daily returns using GBM formula
    daily_returns = np.exp(
        (EXPECTED_RETURN - 0.5 * VOLATILITY**2) / NUM_DAYS
        + VOLATILITY * np.random.normal(0, 1, NUM_DAYS) / np.sqrt(NUM_DAYS)
    )

    # Calculate price series
    price_series = LAST_PRICE * np.cumprod(daily_returns)

    # Append the end price of each simulation to the matrix
    all_simulated_price[x] = price_series[-1]

    # Calculate the liquidity provider payoffs each day
    provider_payoff = SUPPLIED_AMOUNT * liquidity_provider_payoff_v3(
        SUPPLIED_PRICE, price_series, fee=0.003
    )
    all_simulated_provider_payoff[x] = provider_payoff

    # Initialize the options_value array
    options_value = np.zeros(NUM_DAYS)

    # Calculate the value of the put options each day
    for day in range(NUM_DAYS):
        # remaining_maturity = MATURITY - (day / 365)
        options_value[day] = NUM_OPTIONS * black_scholes(
            price_series[day],
            STRIKE_PRICE,
            MATURITY,
            INTEREST_RATE,
            VOLATILITY,
            option_type="call",
        )

    all_simulated_options_value[x] = options_value

    # Calculate liquidity providers payoff including options hedge
    provider_payoff_with_options = SUPPLIED_AMOUNT * (
        1 + provider_payoff + options_value
    )
    all_simulated_provider_payoff_with_options[x] = provider_payoff_with_options

# Plot the liquidity provider payoff each day
plt.figure(1)
plt.title("Liquidity Provider Payoff Over Time due to Impermanent Loss")
for provider_payoff in all_simulated_provider_payoff:
    plt.plot(provider_payoff)

# Plot the liquidity provider payoff with options each day
plt.figure(2)
plt.title("Liquidity Provider Payoff Over Time with Hedge")
for provider_payoff in all_simulated_provider_payoff_with_options:
    plt.plot(provider_payoff)

plt.show()

# Calculate the expected payoff to the liquidity provider without options
expected_payoff_without_options = np.mean(all_simulated_provider_payoff[:, -1])

# Calculate the expected payoff to the liquidity provider with options
expected_payoff_with_options = np.mean(
    all_simulated_provider_payoff_with_options[:, -1]
)

# Print the expected payoffs
print(
    "Expected payoff to the liquidity provider without options: ",
    expected_payoff_without_options,
)
print(
    "Expected payoff to the liquidity provider with options: ",
    expected_payoff_with_options,
)

save_to_csv(
    all_simulated_provider_payoff,
    all_simulated_provider_payoff_with_options,
    all_simulated_options_value,
    "all_data.csv",
)
