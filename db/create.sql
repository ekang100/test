-- Feel free to modify this file to match your development goal.
-- Here we only create 3 tables for demo purpose.

-- if you look in psql for some reason when you change the primary keys in here it doesn't actually change so that might be why idk

CREATE TABLE Users (
    id INT NOT NULL GENERATED BY DEFAULT AS IDENTITY,
    address VARCHAR NOT NULL,
    email VARCHAR UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    firstname VARCHAR(255) NOT NULL CONSTRAINT real_first_name CHECK (firstname ~ '^[A-Za-z]+$'), 
    lastname VARCHAR(255) NOT NULL CONSTRAINT real_last_name CHECK (lastname ~ '^[A-Za-z]+$'),
    balance DECIMAL(10, 2) NOT NULL DEFAULT 0.00 CHECK (balance >= 0.00), 
    isSeller BOOLEAN DEFAULT FALSE,
    isVerified BOOLEAN DEFAULT FALSE,
    verifiedDate timestamp without time zone NOT NULL DEFAULT (current_timestamp AT TIME ZONE 'UTC'),
    bio VARCHAR(500) DEFAULT NULL,
    avatar INT NOT NULL DEFAULT 1,
    PRIMARY KEY (id) -- this overwrites the previous primary key but idk if that's what we want (but it makes the tables that reference uid work)
);

--withdraw needs to be a function to add or remove balance
--pubProfile should be a view from User (name, accountID, PubProfileID)

CREATE TABLE Products (
    productid INT NOT NULL PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    name text UNIQUE NOT NULL,
    price DECIMAL(12,2) NOT NULL,
    description text,
    category VARCHAR(255) NOT NULL,
    image_path VARCHAR(255) DEFAULT NULL,
    available BOOLEAN DEFAULT FALSE,
    avg_rating DECIMAL DEFAULT 0
    --seller_id INT REFERENCES Users(id) --changing schema bc multiple products can be sold by a seller and multiple sellers can sell a product
    --CONSTRAINT same_product_different_sellers UNIQUE (name, description)
);

CREATE TABLE ProductsForSale ( -- do we need price here
    -- id INT NOT NULL PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
    productid INT NOT NULL REFERENCES Products(productid),
    uid INT NOT NULL REFERENCES Users(id),
    quantity INT NOT NULL,
    PRIMARY KEY (productid, uid)
);

CREATE TABLE Cart (
    buyerid INT NOT NULL REFERENCES Users (id), -- trying to identify cart by the user instead of using the cartid in Users table
    -- cartid INT NOT NULL PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY REFERENCES Users(cartid),
    cartid INT NOT NULL PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    uniqueItemCount INT NOT NULL CHECK (uniqueItemCount>=0),
    totalCartPrice DECIMAL(65,2) NOT NULL CHECK (totalCartPrice>=0.0)
); 


CREATE TABLE OrdersInProgress (
    -- address VAsRCHAR NOT NULL REFERENCES Users(address), -- this doesn't work because it has to reference a primary key or a unique key
    -- do we need address here? im not gonna change it rn
    -- lineid INT NOT NULL REFERENCES LineItem(lineid), -- update maybe
    -- quantities INT NOT NULL REFERENCES LineItem(quantities), -- this is causing issues
    orderid INT NOT NULL PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    -- sellerid INT NOT NULL REFERENCES Users(id),
    buyerid INT REFERENCES Users(id) DEFAULT NULL,
    entireOrderFulfillmentStatus BOOLEAN DEFAULT NULL,
    tipAmount DECIMAL (65,2) DEFAULT NULL CHECK (tipAmount >=0.00)
    -- productid INT NOT NULL REFERENCES Products(productid)
    --fulfillment status (for the whole order)



    --get status, date, quantities from lineItem
);

CREATE TABLE LineItem (
    lineid INT NOT NULL PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY, -- updated
    cartid INT NOT NULL REFERENCES Cart(cartid),
    productid INT NOT NULL REFERENCES Products(productid),
    quantities INT NOT NULL CHECK (quantities>=1),
    unitPrice DECIMAL(65,2) NOT NULL CHECK (unitPrice>=0.00),
    buyStatus BOOLEAN DEFAULT FALSE, --this checks if an item is bought or not
    fulfilledStatus BOOLEAN DEFAULT FALSE,
    time_purchased timestamp without time zone NOT NULL DEFAULT (current_timestamp AT TIME ZONE 'UTC'),
    time_fulfilled timestamp without time zone NOT NULL DEFAULT (current_timestamp AT TIME ZONE 'UTC'),
    orderid INT REFERENCES OrdersInProgress(orderid) DEFAULT NULL,
    sellerid INT NOT NULL REFERENCES Users(id)
    
    -- PRIMARY KEY (lineid) -- updated
);


-- Not having sellers table has thrown a wrench into things
CREATE TABLE Reviews (
    entity_id SERIAL PRIMARY KEY,       
    product_id INT REFERENCES Products(productid),
    uid INT NOT NULL REFERENCES Users(id),  
    seller_id INT REFERENCES Users(id),      
    type VARCHAR(10) CHECK (type IN ('product', 'seller')) NOT NULL,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comments TEXT,
    date timestamp without time zone NOT NULL DEFAULT (current_timestamp AT TIME ZONE 'UTC'),
    CHECK (
        (type = 'product' AND product_id IS NOT NULL AND seller_id IS NULL) OR
        (type = 'seller' AND product_id IS NULL AND seller_id IS NOT NULL)
    ),
    UNIQUE(uid, product_id, type),
    UNIQUE(uid, seller_id, type)  
);




---------------------Triggers---------------------------
-- CREATE OR REPLACE FUNCTION ensure_one_review_per_seller()
-- RETURNS TRIGGER AS $$
-- BEGIN
--   IF EXISTS (
--     SELECT 1 FROM Reviews
--     WHERE uid = NEW.uid
--       AND seller_id = NEW.seller_id
--       AND type = 'seller'
--   ) THEN
--     RAISE EXCEPTION 'This user has already reviewed this seller.';
--   END IF;
--   RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER trg_ensure_one_review_per_seller
-- BEFORE INSERT OR UPDATE ON Reviews
-- FOR EACH ROW
-- WHEN (NEW.type = 'seller')
-- EXECUTE FUNCTION ensure_one_review_per_seller();


CREATE OR REPLACE FUNCTION check_reviewee_is_seller()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.type = 'seller' THEN
    IF (SELECT isSeller FROM Users WHERE id = NEW.seller_id) = FALSE THEN
      RAISE EXCEPTION 'Cannot add a seller review for a user who is not a seller.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_reviewee_is_seller
BEFORE INSERT OR UPDATE ON Reviews
FOR EACH ROW
EXECUTE FUNCTION check_reviewee_is_seller();


---------------------Views------------------------------
CREATE VIEW PubProfile AS
SELECT id AS account_id, firstname || ' ' || lastname AS name, email, address, isSeller, isVerified, bio, avatar
FROM Users;