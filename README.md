# Analysis of Walmart Sales in Stormy Weather
Analysis of Walmart sales patterns around severe weather events using SQL queries

Walmart, the world’s largest retailer by revenue, made $642 billion in global sales in 2024, with over 11,000 stores in 27 countries. It handles a diverse product mix across regions with varying climates. Extreme weather events — like blizzards or heavy rain — can drastically alter consumer behavior. Understanding how sales fluctuate during such events helps Walmart optimize inventory, streamline logistics, and improve marketing effectiveness.

## Goal
This project explores how sales of essential products change before, during, and after severe weather events. We aim to identify demand patterns that inform smarter stocking strategies, and determine which stores are most affected by storms and which remain resilient. 

## Dataset
The dataset for this project is from Kaggle (link:[https://www.kaggle.com/c/walmart-recruiting-sales-in-stormy-weather/data]), provided by Walmart for a challenge on predicting sales during stormy weather. It includes three CSV files
- Train.csv contains daily sales data for 111 products sold across 45 Walmart locations between Jan 1, 2012, and Oct 31, 2014
- Weather.csv contains daily weather data for 20 weather stations, including metrics like temperature, precipitation, and snowfall.
- Key.csv contains the mapping between stores and weather stations.
The 45 stores are covered by 20 weather stations, some of which are shared by nearby locations.

### Entity-Relationship Diagram
![ERD](https://github.com/user-attachments/assets/03f3e5de-f857-4d1c-97bc-41a39055299e)

## Business Questions and KPIs

We define a stormy day as one with over 1 inch of rain or more than 2 inches of snow. All other days, including those with missing weather data, are treated as non-stormy.

The key business questions are:
- Which products are most sensitive to weather changes?
  - daily average sales on stormy vs non-stormy days.
- Do certain products sell better in snow vs rain?
  - percentage change in average sales on snowy and rainy days compared to non-stormy ones.
- Which items show signs of panic buying before storms?
  - daily average sales one day before stormy events to those on non-stormy days.
- Which stores are most affected or resilient during storms?
  - store-level percentage change in daily average sales on stormy days vs non-stormy days.
