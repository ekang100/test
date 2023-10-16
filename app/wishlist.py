from flask import render_template
from flask_login import current_user
import datetime
from flask import jsonify

from .models.product import Product
from .models.purchase import Purchase
from .models.wishlist import WishlistItem

from flask import redirect, url_for

from flask import Blueprint
bp = Blueprint('wishlist', __name__)


@bp.route('/wishlist')
def wishlist():
    #currentUID = current_user.id
    if current_user.is_authenticated:
        wishlist = WishlistItem.get_all_by_uid_since(current_user.id, datetime.datetime(1950, 9, 14, 0, 0, 0)) 
        # return render_template('wishlist.html',
        #                        wishlist=wishlist)
        return jsonify([item.__dict__ for item in wishlist])


    else:
        return jsonify({}), 404
    
@bp.route('/wishlist/add/<int:product_id>', methods=['POST'])
def wishlist_add(product_id):
    if current_user.is_authenticated:
        WishlistItem.add(current_user.id, product_id, datetime.datetime.now())
        return redirect(url_for('wishlist.wishlist'))
    else:
        return jsonify({}), 404


    #return jsonify([item.__dict__ for item in wishlist])
