
-- Select students older than 30
SELECT * FROM students WHERE age > 30;

-- Select IT or Electronics department
SELECT * FROM students WHERE department IN ('IT', 'Electronics');
-- Select students with age between 25 and 35
SELECT * FROM students WHERE age BETWEEN 25 AND 35;

-- Select students not from 'IT' department
SELECT * FROM students WHERE department != 'IT';

-- Select students from 'Hyderabad' or 'Delhi'
SELECT * FROM students WHERE city IN ('Hyderabad', 'Delhi');
