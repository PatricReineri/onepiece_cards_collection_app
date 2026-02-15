# One Piece Collector App

A sophisticated Flutter application designed for One Piece Trading Card Game collectors. This app have a comprehensive database to manage collections, track market values, and organize cards efficiently.

## Application Overview

The application is structured into several key areas allowing users to browse sets, track specific rare cards, calculate collection value in real-time, and add new cards via manual entry or camera scanning.

### Pages & Features

#### 1. Home Page (Collection Overview)
The central hub of the application. Here, users can view all released card sets with visual completion indicators.
- **Features**: Sort sets by release date or completion percentage, Sync data from API, Import/Export collection (JSON).
- **Navigation**: Access to Sets Checkpoint and Global Search.

![Home Page](images/home_page.jpg)

#### 2. Set Detail Page
(Accessed by tapping a set in Home)
Displays all cards within a specific set. Allows users to toggle collected status and view individual card details.

![Set Detail Page](images/set_detail_page.jpg)

#### 3. Rare & Valuable Dashboard
A dedicated dashboard for the "Crown Jewels" of your collection.
- **Features**: Displays total collection market value, highlights high-rarity cards (SEC, SR, SP, L), and lists top cards by market price.
- **Functionality**: Pull to refresh market prices.

![Rare Page](images/rare_page.jpg)

#### 4. Add Card
The input interface for expanding the collection.
- **Manual Mode**: Enter card codes (e.g., OP01-001) with validation.
- **Camera Mode**: AI-assisted scanning to identify cards via camera (in development).

![Add Card Page](images/add_card_page.jpg)

#### 5. Search Card
A global search tool to find any card in the database by name or code, regardless of ownership status.

![Search Card Page](images/search_card_page.jpg)

#### 6. Sets Checkpoint
A compact, list-based view of the collection organized by set, useful for quick inventory checks.

![Sets Checkpoint Page](images/sets_checkpoint_page.jpg)

#### 7. Rare & Valuable Lists
Detailed grid views for browsing all rare cards or all valuable cards in the collection.

![Rare Cards List](images/all_rare_cards_page.jpg)

---

## Legal & Copyright

This project is a fan-made application and is not affiliated with, endorsed, sponsored, or specifically approved by Bandai or the creators of One Piece.

**ONE PIECE CARD GAME**  
@Eiichiro Oda/Shueisha @Eiichiro Oda/Shueisha, Toei Animation
