<img src="onepiece_collector/lib/data/images/logo_app.png" alt="App Logo" width="180" />

# One Piece Collector App

A sophisticated and responsive Flutter application designed for One Piece Trading Card Game collectors. This app have a comprehensive database to manage collections, track market values, and organize cards efficiently.

## Application Overview

The application is structured into several key areas allowing users to browse sets, track specific rare cards, calculate collection value in real-time, and add new cards via manual entry.

### Pages & Features

#### 1. Home Page (Collection Overview)
The central hub of the application. Here, users can view all released card sets with visual completion indicators.
- **Features**: Sort sets by release date or completion percentage, Sync data from API, Import/Export collection (JSON).
- **Navigation**: Access to Sets Checkpoint and Global Search.

<img src="images/home_page.png" alt="Home Page" width="360" />

#### 2. Set Detail Page
(Accessed by tapping a set in Home)
Displays all cards within a specific set. Allows users to toggle collected status and view individual card details.

<img src="images/set_detail_page.png" alt="Set Detail Page" width="360" />

#### 2.5 Show missing cards in a set
A feature within the Set Detail Page that highlights which cards are missing from the user's collection, making it easier to identify gaps and prioritize acquisitions.

<img src="images/missing_cards.png" alt="Missing Cards" width="360" />

#### 3. Rare & Valuable Dashboard
A dedicated dashboard for the "Crown Jewels" of your collection.
- **Features**: Displays total collection market value, highlights high-rarity cards (SEC, SR, SP, L), and lists top cards by market price.
- **Functionality**: Pull to refresh market prices.

<img src="images/rare_page.png" alt="Rare Page" width="360" />

#### 4. Search Card
A global search tool to find any card in the database by name or code, regardless of ownership status.

<img src="images/search_card_page.png" alt="Search Card Page" width="360" />

#### 5. Sets Checkpoint
A compact, list-based view of the collection organized by set, useful for quick inventory checks.

<img src="images/sets_checkpoint_page.png" alt="Sets Checkpoint Page" width="360" />

#### 6. Rare & Valuable Lists
Detailed grid views for browsing all rare cards or all valuable cards in the collection.

<img src="images/all_rare_cards_page.png" alt="Rare Cards List" width="360" />

---

## Legal & Copyright

This project is a fan-made application and is not affiliated with, endorsed, sponsored, or specifically approved by Bandai or the creators of One Piece.

**ONE PIECE CARD GAME**  
@Eiichiro Oda/Shueisha @Eiichiro Oda/Shueisha, Toei Animation

Card information is provided using the OPTCG API: https://optcgapi.com/documentation#docu-4
