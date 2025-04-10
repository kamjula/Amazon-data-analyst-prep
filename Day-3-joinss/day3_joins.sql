CREATE TABLE Customers (
  CustomerID INT,
  Name VARCHAR(50)
);

CREATE TABLE Orders (
  OrderID INT,
  CustomerID INT,
  Product VARCHAR(50)
);
SELECT c.Name, o.Product
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID;
