## Pandas

import pandas as pd
p = pd.read_csv("data/purchases.csv")
p.head()
p["amount"].sum()

# Sum the amount column by country.
p.groupby("country").agg(total=("amount", "sum")).reset_index()
  
# Sum after removing 'discount'.
p.groupby("country") \
  .apply(lambda df: (df["amount"] - df["discount"]).sum()) \
  .reset_index() \
  .rename(columns={0: "total"}) 

# Remove outliers before summing.
p.query("amount <= amount.median() * 10") \
  .groupby("country") \
  .apply(lambda df: (df["amount"] - df["discount"]).sum()) \
  .reset_index() \
  .rename(columns={0: "total"})

# Remove outliers based on median within country.
p.groupby("country") \
  .apply(lambda df: df[df["amount"] <= df["amount"].median() * 10]) \
  .reset_index(drop=True) \
  .groupby("country") \
  .apply(lambda df: (df["amount"] - df["discount"]).sum()) \
  .reset_index() \
  .rename(columns={0: "total"})  

## Polars

import polars as pl
p2 = pl.read_csv("data/purchases.csv")
p2.head()
p2["amount"].sum()
p2.select(pl.col('amount')).sum()  # result is still a dataframe

# Sum the amount column by country.
p2.groupby("country").agg(total=pl.col("amount").sum()).sort("country")

# Sum after removing 'discount'.
p2.groupby("country").agg((pl.col("amount") - pl.col("discount")).sum().alias("total")).sort("country")
p2.groupby("country").agg(total=(pl.col("amount") - pl.col("discount")).sum()).sort("country")

# Remove outliers before summing.
p2.filter(pl.col("amount") <= pl.col("amount").median() * 10) \
          .groupby("country") \
          .agg(total=(pl.col("amount") - pl.col("discount")).sum()).sort("country")

# Remove outliers based on median within country.
p2.groupby("country") \
  .agg(pl.col("amount").median().alias("country_median")) \
  .join(p2, on="country") \
  .filter(pl.col("amount") <= pl.col("country_median") * 10) \
  .groupby("country") \
  .agg(total=(pl.col("amount") - pl.col("discount")).sum()).sort("country")


