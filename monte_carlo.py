import numpy as np
import matplotlib.pyplot as plt
from black_scholes import black_scholes
from provider_payoff import liquidity_provider_payoff_v3
from save_csv import save_to_csv

# Set the parameters
NUM_SIMULATIONS = 100
NUM_DAYS = 365
LAST_PRICE = 1957  # This should be the current price of ETH
VOLATILITY = 0.4  # This should be the historical VOLATILITY of ETH
EXPECTED_RETURN = 0.00  # This should be the expected return of ETH
NUM_ETH = 1  # Amount of ETH in collateral
NUM_OPTIONS = 1  # Number of options bought
STRIKE_PRICE = LAST_PRICE * 1.3  # 30%+ of the starting price
MATURITY = 365 / 365  # Maturity of the the option
INTEREST_RATE = 0.04
SUPPLIED_PRICE = 1957
SUPPLIED_AMOUNT = 1  # Amount of currency supplied by the liquidity provider

previous_position_value = SUPPLIED_PRICE * SUPPLIED_AMOUNT

# Create an empty matrix to hold the end price data
all_simulated_price = np.zeros((NUM_SIMULATIONS, NUM_DAYS))

# Create an empty matrix to hold the provider payoff data
all_simulated_provider_payoff = np.zeros((NUM_SIMULATIONS, NUM_DAYS))

# Create an empty matrix to hold the portfolio value data
all_simulated_provider_payoff_with_options = np.zeros((NUM_SIMULATIONS, NUM_DAYS))

# Create an empty matrix to hold the options value data
all_simulated_options_value = np.zeros((NUM_SIMULATIONS, NUM_DAYS))

unhedged_positions = np.zeros((NUM_SIMULATIONS, NUM_DAYS))

hedged_positions = np.zeros((NUM_SIMULATIONS, NUM_DAYS))

# Set the plot size
plt.figure(figsize=(10, 5))

# Run the Monte Carlo simulation
for x in range(NUM_SIMULATIONS):
    # Calculate daily returns using GBM formula
    daily_returns = np.exp(
        (EXPECTED_RETURN - 0.5 * VOLATILITY**2) / NUM_DAYS
        + VOLATILITY * np.random.normal(0, 1, NUM_DAYS) / np.sqrt(NUM_DAYS)
    )

    # Calculate price series
    price_series = LAST_PRICE * np.cumprod(daily_returns)

    # Plot each simulation
    plt.figure(1)
    plt.plot(price_series)
    plt.title("Price Series Simulation")

    # Append the end price of each simulation to the matrix
    all_simulated_price[x] = price_series[-1]

    # # Calculate the liquidity provider payoffs each day
    # provider_payoff = SUPPLIED_AMOUNT * liquidity_provider_payoff_v3(
    #     SUPPLIED_PRICE, price_series, fee=0.003
    # )
    # all_simulated_provider_payoff[x] = provider_payoff

    # position_value = previous_position_value + provider_payoff

    # Initialize the options_value array
    options_value = np.zeros(NUM_DAYS)

    for day in range(NUM_DAYS):
        # calculate impermanent loss for the day
        impermanent_loss = (
            (SUPPLIED_PRICE - price_series[day]) * SUPPLIED_AMOUNT
            if price_series[day] > SUPPLIED_PRICE
            else 0.003 * price_series[day]
        )

        # calculate position value for the day
        position_value = previous_position_value + impermanent_loss

        unhedged_positions[x, day] = position_value

        # Calculate option value for the day
        remaining_maturity = MATURITY - (day / 365)
        options_value = NUM_OPTIONS * black_scholes(
            price_series[day],
            STRIKE_PRICE,
            remaining_maturity,
            INTEREST_RATE,
            VOLATILITY,
            option_type="call",
        )

        total_hedged_position = position_value + options_value
        hedged_positions[x, day] = total_hedged_position

    all_simulated_options_value[x] = options_value

    # # Calculate liquidity providers payoff including options hedge
    # if x == 0:  # For the first simulation, there's no previous day
    #     provider_payoff_with_options = provider_payoff + all_simulated_options_value[0]
    # else:
    #     provider_payoff_with_options = provider_payoff + all_simulated_options_value[x]
    # all_simulated_provider_payoff_with_options[x] = provider_payoff_with_options

# print("provider payoff", all_simulated_provider_payoff)
# print("provider payoff with options", all_simulated_provider_payoff_with_options)
# print("options value", options_value[x])

min_value = min(np.min(unhedged_positions), np.min(hedged_positions))
max_value = max(np.max(unhedged_positions), np.max(hedged_positions))

# Plot the liquidity provider payoff each day
plt.figure(2)
plt.title("Liquidity Provider Payoff Over Time")
for position_value in unhedged_positions:
    plt.plot(position_value)
plt.ylim([min_value, max_value + 1000])

# Plot the liquidity provider payoff with options each day
# plt.figure(3)
# plt.title("Liquidity Provider Payoff with Hedge Over Time")
# for provider_payoff in all_simulated_provider_payoff_with_options:
#     plt.plot(provider_payoff)

# plt.figure(4)
# plt.title("Options Value Over Time")
# for options_value in all_simulated_options_value:
#     plt.plot(options_value)

plt.figure(5)
plt.title("LP Hedged Pool")
for total_value in hedged_positions:
    plt.plot(total_value)
plt.ylim([min_value, max_value + 1000])

# Show the plot
plt.show()

# Calculate the expected payoff to the liquidity provider without options
expected_payoff_without_options = np.mean(unhedged_positions[:, -1])

# Calculate the expected payoff to the liquidity provider with options
expected_payoff_with_options = np.mean(hedged_positions[:, -1])

# Print the expected payoffs
print(
    "Expected payoff to the liquidity provider without options: ",
    expected_payoff_without_options,
)
print(
    "Expected payoff to the liquidity provider with options: ",
    expected_payoff_with_options,
)
