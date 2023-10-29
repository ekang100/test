from flask import current_app as app

class Reviews:
    def __init__(self, type, entity_id, uid, rating, comments, date):
        self.type = type  # 'product' or 'seller'
        self.entity_id = entity_id  # either productid or sellerid
        self.uid = uid
        self.rating = rating
        self.comments = comments
        self.date = date

    @staticmethod
    def get(type, entity_id, uid):
        try:
            rows = app.db.execute('''
SELECT type, entity_id, uid, rating, comments, date
FROM Reviews
WHERE type = :type AND entity_id = :entity_id AND uid = :uid
''',
                                  type=type,
                                  entity_id=entity_id,
                                  uid=uid)
            return Reviews(*(rows[0])) if rows else None
        except Exception as e:
            # You can log the error here for further debugging
            raise ValueError(f"Error fetching review: {str(e)}") from e
        
    @staticmethod
    def get_most_recent_by_uid(uid, limit=5):
            rows = app.db.execute('''
    SELECT type, entity_id, uid, rating, comments, date
    FROM Reviews
    WHERE uid = :uid
    ORDER BY date DESC
    LIMIT :limit
    ''',
                                uid=uid,
                                limit=limit)
            if not rows:
                raise ValueError(f"No reviews found for user_id: {uid}")
            return [Reviews(*row) for row in rows]


