CREATE TABLE customer(
  customer_id   serial  PRIMARY KEY
  , first_name  text    NOT NULL
  , last_name   text    NOT NULL
);
CREATE TABLE invoice(
  invoice_id      serial  PRIMARY KEY
  , customer_id   int     NOT NULL REFERENCES customer
  , invoice_date  date  NOT NULL
  , due_date      date
);
