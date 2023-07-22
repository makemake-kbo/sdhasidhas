import pandas as pd


def save_to_csv(provider_payoff, provider_payoff_with_options, options_value, filename):
    """
    Save the provided data arrays to a CSV file.

    Parameters:
    provider_payoff (numpy.ndarray): The provider payoff data.
    provider_payoff_with_options (numpy.ndarray): The provider payoff with options data.
    options_value (numpy.ndarray): The options value data.
    filename (str): The name of the CSV file to save the data to.

    Returns:
    None
    """
    # Create a DataFrame for each data array
    df_provider_payoff = pd.DataFrame(provider_payoff.T)
    df_provider_payoff["Type"] = "Provider Payoff"

    df_provider_payoff_with_options = pd.DataFrame(provider_payoff_with_options.T)
    df_provider_payoff_with_options["Type"] = "Provider Payoff with Options"

    df_options_value = pd.DataFrame(options_value.T)
    df_options_value["Type"] = "Options Value"

    # Concatenate the DataFrames along the row axis
    df = pd.concat(
        [df_provider_payoff, df_provider_payoff_with_options, df_options_value]
    )

    # Save the DataFrame to a CSV file
    df.to_csv(filename, index=False)
