#! /usr/bin/python

# import packages
import pandas as pd
import openpyxl

df = pd.read_csv('input.csv')
df.to_excel('output.xlsx')
