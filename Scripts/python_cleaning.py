import numpy as np
import pandas as pd


# Load raw file and re-export with clean, uniform formatting
def utf8_format(path):
    df = pd.read_csv(
        r"path"
    )
    df.to_csv(
        r"path",
        index=False, encoding= "UTF-8"
    )
    return print(f'{df} succesfully formatted to utf-8')

#
def clean_category_names(df, column, replace_label):
    """Remove stray line breaks, swap underscores for spaces, title-case, fix labels."""
    df = df.copy()
    df[column] = (
        df[column]
        .str.replace("\r", "", regex=False)
        .str.strip()
        .str.replace("_", " ", regex=False)
        .str.title()
        .replace(replace_label)
    )
    return df


def save_chart(fig, path):
    """Save a figure into the Assets folder."""
    fig.savefig(path)
    print(f"Saved: {path}")


def style_month_axis(ax, dates):
    """Put month labels on the x axis and return the x positions."""
    x = np.arange(len(dates))
    ax.set_xticks(x)
    ax.set_xticklabels(dates.dt.strftime("%b %Y"), rotation=30, ha="right")
    return x