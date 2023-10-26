from flask import current_app as app


class Cart:
    def __init__(self, buyerid, cartid, uniqueItemCount, totalCartPrice):
        self.buyerid = buyerid
        self.cartid = cartid
        self.uniqueItemCount = uniqueItemCount
        self.totalCartPrice = totalCartPrice

    @staticmethod
    def get_cartID_from_buyerid(buyerid): #this returns only the cartID
        rows = app.db.execute('''
SELECT cartid, buyerid, uniqueItemCount, totalCartPrice
FROM Cart
WHERE buyerid = :buyerid
''', 
                              buyerid = buyerid)
        return ((rows[0])[0]) if rows else None
    
    @staticmethod
    def get_cart_from_buyerid(buyerid): #this returns the WHOLE CART
        rows = app.db.execute('''
SELECT cartid, buyerid, uniqueItemCount, totalCartPrice
FROM Cart
WHERE buyerid = :buyerid
''', 
                              buyerid = buyerid)
        return Cart(*(rows[0])) if rows else None

    
    @staticmethod
    def get_unique_item_count(cartid):
        rows = app.db.execute('''
SELECT buyerid, cartid, uniqueItemCount, totalCartPrice
FROM Cart
WHERE cartid = :cartid
''', 
                              cartid = cartid)
        return Cart(*(rows[0])) if rows else None

    @staticmethod
    def update_total_cart_price(cartid): #going to need to add a constraint here
        rows = app.db.execute('''
UPDATE Cart
SET totalCartPrice = (SELECT SUM(quantities * unitPrice)
                            FROM LineItem
                            WHERE cartid = :cartid AND status = FALSE)
WHERE cartid = :cartid
''', 
                              cartid = cartid)
        return None
    

    @staticmethod
    def update_number_unique_items(cartid): #going to need to add a constraint here
        rows = app.db.execute('''
UPDATE Cart
SET uniqueItemCount = (SELECT Count(LineItem.cartid)
                            FROM LineItem
                            WHERE LineItem.cartid = :cartid AND LineItem.status = FALSE)
WHERE cartid = :cartid
''', 
                              cartid = cartid)
        return None


