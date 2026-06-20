# AI SQLite Query Assistant Demo

This demo shows how to combine ChatGPT with the AI DBase Dictionary component to generate SQLite SELECT queries from natural language.

## Technologies used

- Lazarus
- ZeosLib
- SQLite
- TCHATGPT
- TAISQLiteDictionary
- TZConnection
- TZQuery
- TDataSource
- TDBGrid

## Workflow

1. Create a demo SQLite database.
2. Connect to the database using ZeosLib.
3. Generate the database dictionary using AI DBase Dictionary.
4. Type a natural language request.
5. Generate SQLite SQL using the LLM.
6. Review or edit the generated SQL.
7. Execute the SQL using ZeosLib.
8. View the result in a DBGrid.

## Demo database

The demo creates a sales database with the following tables:

- customers
- categories
- products
- promotions
- sales
- sale_items
- payments

## Example requests

- Show total sales by customer.
- List the best-selling products.
- Show sales with customer name, sale date and total amount.
- Show products that are currently in promotion.
- Show total revenue by payment method.
- Show pending sales.
- Show products with low stock.
- Show customers who bought notebooks.
- Show monthly sales totals.
- Show the top 5 customers by revenue.

## Safety

The demo only allows SELECT and WITH queries to be executed.

Commands such as INSERT, UPDATE, DELETE, DROP, ALTER, CREATE, PRAGMA, ATTACH, DETACH, VACUUM, BEGIN, COMMIT and ROLLBACK are blocked before execution.

## Important note

All database access in this demo is performed using ZeosLib.

The demo does not use SQLDB, TSQLite3Connection, sqlite3conn or direct sqlite3 API calls.
