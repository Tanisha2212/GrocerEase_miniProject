from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
import pandas as pd
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.cluster import KMeans
from typing import List, Dict, Any

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For development only; restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Expanded Recipe Dataset
recipes = [
    {"id": 1, "name": "Pasta Carbonara", "ingredients": ["pasta", "eggs", "cheese", "bacon", "pepper"]},
    {"id": 2, "name": "Greek Salad", "ingredients": ["lettuce", "tomato", "cucumber", "olive oil", "feta cheese", "olives"]},
    {"id": 3, "name": "Vegetable Omelette", "ingredients": ["eggs", "cheese", "bell pepper", "tomato", "onion", "spinach"]},
    {"id": 4, "name": "Chicken Stir Fry", "ingredients": ["chicken", "broccoli", "carrot", "bell pepper", "soy sauce", "rice"]},
    {"id": 5, "name": "Berry Smoothie", "ingredients": ["banana", "strawberry", "blueberry", "yogurt", "honey", "milk"]},
    {"id": 6, "name": "Mushroom Risotto", "ingredients": ["rice", "mushroom", "onion", "garlic", "broth", "parmesan"]},
    {"id": 7, "name": "Beef Tacos", "ingredients": ["beef", "tortilla", "tomato", "lettuce", "cheese", "onion", "salsa"]}
]

# Convert ingredients to vector format
recipe_df = pd.DataFrame(recipes)
recipe_df['ingredient_str'] = recipe_df['ingredients'].apply(lambda x: " ".join(x))

# Expanded Purchase History with more data for ML
purchase_history = {
    "user1": [
        # Past purchases for user1 - showing repeating patterns
        ["milk", "bread", "eggs", "cheese", "chicken", "potatoes", "onions"],
        ["milk", "cereal", "banana", "coffee", "sugar"],
        ["bread", "butter", "jam", "eggs", "bacon"],
        ["chicken", "broccoli", "rice", "soy sauce", "garlic"],
        ["milk", "bread", "coffee", "cereal", "banana"],
        ["pasta", "tomato sauce", "ground beef", "cheese", "onions", "garlic"],
        ["milk", "eggs", "cheese", "potatoes", "chicken", "carrots"],
        ["bread", "peanut butter", "jam", "banana", "milk"],
        ["rice", "beans", "cheese", "salsa", "tortillas"],
        ["milk", "bread", "eggs", "butter", "bacon", "potatoes"]
    ],
    "user2": [
        ["rice", "beans", "tomato", "onion", "cilantro", "chicken"],
        ["pasta", "tomato sauce", "cheese", "garlic bread"],
        ["lettuce", "tomato", "cucumber", "avocado", "chicken", "dressing"],
        ["rice", "beans", "avocado", "salsa", "tortillas", "cheese"],
        ["quinoa", "kale", "sweet potato", "chickpeas", "tahini"]
    ]
}

# Flatten purchase history for ML processing
def flatten_purchase_history(user_id):
    """Convert a user's purchase history into a flattened list of unique items"""
    if user_id in purchase_history:
        # Flatten the list of lists and get unique items
        return list(set(item for sublist in purchase_history[user_id] for item in sublist))
    return []

# Process purchase history into item frequencies
def get_item_frequencies():
    """Get all unique items and their frequencies across all users"""
    all_items = {}
    for user, purchases in purchase_history.items():
        for purchase_list in purchases:
            for item in purchase_list:
                if item in all_items:
                    all_items[item] += 1
                else:
                    all_items[item] = 1
    return all_items

@app.get("/recommend")
def recommend_recipe(ingredients: str = Query(..., description="Comma-separated ingredients")):
    """Recommend recipes based on user ingredients"""
    user_ingredients = ingredients.split(",")
    user_ingredients = [ing.strip().lower() for ing in user_ingredients]
    
    # Calculate similarity based on ingredient overlap
    similarity_scores = []
    for recipe in recipes:
        recipe_ingredients = set(recipe["ingredients"])
        user_ingredients_set = set(user_ingredients)
        
        # Count matching ingredients
        matching = len(recipe_ingredients.intersection(user_ingredients_set))
        total = len(recipe_ingredients)
        
        # Calculate a similarity score (percentage of recipe ingredients matched)
        if total > 0:
            score = matching / total
            similarity_scores.append((recipe, score))
    
    # Sort by similarity score
    similarity_scores.sort(key=lambda x: x[1], reverse=True)
    
    # Return best match or empty if no matches
    if similarity_scores and similarity_scores[0][1] > 0:
        return similarity_scores[0][0]
    else:
        return {"message": "No recipe matches found"}

@app.get("/predict-shopping-list")
def predict_shopping_list(user_id: str = Query(..., description="User ID")):
    """Predicts shopping list based on past purchases using ML techniques"""
    if user_id not in purchase_history:
        return {"error": f"User {user_id} not found", "recommended_items": []}
    
    # Get all unique items across all users
    all_items_freq = get_item_frequencies()
    items = list(all_items_freq.keys())
    
    # Create purchase vectors for each user (1 if they've bought the item, 0 otherwise)
    purchase_vectors = {}
    for user in purchase_history:
        user_items = flatten_purchase_history(user)
        purchase_vectors[user] = [1 if item in user_items else 0 for item in items]
    
    # Convert to numpy array for ML processing
    users = list(purchase_vectors.keys())
    purchase_matrix = np.array([purchase_vectors[user] for user in users])
    
    # Apply K-means clustering
    n_clusters = min(2, len(users))  # Ensure we don't have more clusters than users
    kmeans = KMeans(n_clusters=n_clusters, random_state=42, n_init=10).fit(purchase_matrix)
    
    # Find which cluster the current user belongs to
    user_index = users.index(user_id)
    user_cluster = kmeans.labels_[user_index]
    
    # Find other users in the same cluster
    similar_users_indices = [i for i, label in enumerate(kmeans.labels_) if label == user_cluster and users[i] != user_id]
    
    # Get frequently purchased items from similar users that the current user hasn't bought
    current_user_items = set(flatten_purchase_history(user_id))
    recommended_items = []
    
    if similar_users_indices:
        # Get items from similar users
        similar_users_items = []
        for idx in similar_users_indices:
            similar_user = users[idx]
            similar_users_items.extend(flatten_purchase_history(similar_user))
        
        # Count frequencies of these items
        item_counts = {}
        for item in similar_users_items:
            if item not in current_user_items:  # Only recommend items the user hasn't bought
                item_counts[item] = item_counts.get(item, 0) + 1
        
        # Sort by frequency and get top items
        recommended_items = sorted(item_counts.keys(), key=lambda x: item_counts[x], reverse=True)[:10]
    
    # If no recommendations from similar users, recommend popular items the user hasn't bought
    if not recommended_items:
        popular_items = sorted(all_items_freq.keys(), key=lambda x: all_items_freq[x], reverse=True)
        recommended_items = [item for item in popular_items if item not in current_user_items][:10]
    
    return {"recommended_items": recommended_items}

# Add an endpoint to check if the API is running
@app.get("/")
def read_root():
    return {"status": "API is running", "endpoints": ["/recommend", "/predict-shopping-list"]}