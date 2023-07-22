import numpy as np


def liquidity_provider_payoff_v3(supplied_price, spotPrice, fee=0.003):
    # Check if the spot price is within the range
    payoff = np.where(
        spotPrice < supplied_price, fee * spotPrice, supplied_price - spotPrice
    )

    return payoff
