// The catalog is data; one name per line would only make it longer.
// dart format off
import 'package:yamt/features/shoppinglist/domain/shopping_shelf.dart';

/// The products the app knows from the start, by shelf and picture, with
/// German and English names. Within a shelf, earlier names are the more
/// common products; the add sheet offers them first.
const shoppingCatalogGroups = <(
  ShoppingShelf,
  ShoppingItemIcon, {
  List<String> de,
  List<String> en,
})>[
  (ShoppingShelf.produce, ShoppingItemIcon.fruit, de: [
    'Äpfel', 'Apfel', 'Bananen', 'Banane', 'Birnen', 'Birne', 'Orangen',
    'Orange', 'Mandarinen', 'Mandarine', 'Clementinen', 'Zitronen',
    'Zitrone', 'Limetten', 'Limette', 'Weintrauben', 'Trauben', 'Erdbeeren',
    'Himbeeren', 'Heidelbeeren', 'Blaubeeren', 'Beeren', 'Kiwi', 'Mango',
    'Ananas', 'Melone', 'Wassermelone', 'Pfirsiche', 'Pfirsich',
    'Nektarinen', 'Pflaumen', 'Kirschen', 'Avocado', 'Avocados',
    'Granatapfel', 'Datteln', 'Feigen', 'Obst',
  ], en: [
    'Apples', 'Apple', 'Bananas', 'Banana', 'Lemon', 'Lime', 'Grapes',
    'Strawberries', 'Blueberries', 'Pear', 'Orange', 'Kiwi', 'Mango',
    'Avocado', 'Avocados',
  ]),
  (ShoppingShelf.produce, ShoppingItemIcon.vegetable, de: [
    'Tomaten', 'Tomate', 'Gurke', 'Gurken', 'Paprika', 'Zwiebeln', 'Zwiebel',
    'Knoblauch', 'Kartoffeln', 'Kartoffel', 'Karotten', 'Karotte', 'Möhren',
    'Möhre', 'Zucchini', 'Aubergine', 'Auberginen', 'Brokkoli', 'Blumenkohl',
    'Kohl', 'Rotkohl', 'Weißkohl', 'Kohlrabi', 'Lauch', 'Porree', 'Sellerie',
    'Spargel', 'Pilze', 'Champignons', 'Mais', 'Kürbis', 'Süßkartoffeln',
    'Süßkartoffel', 'Ingwer', 'Radieschen', 'Rote Bete', 'Fenchel',
    'Rosenkohl', 'Frühlingszwiebeln', 'Schalotten', 'Chili', 'Gemüse',
  ], en: [
    'Tomatoes', 'Tomato', 'Cucumber', 'Onions', 'Onion', 'Garlic',
    'Potatoes', 'Carrots', 'Pepper', 'Mushrooms', 'Ginger', 'Zucchini',
    'Chili',
  ]),
  (ShoppingShelf.produce, ShoppingItemIcon.herb, de: [
    'Salat', 'Kopfsalat', 'Eisbergsalat', 'Rucola', 'Feldsalat', 'Spinat',
    'Petersilie', 'Basilikum', 'Schnittlauch', 'Koriander', 'Minze', 'Dill',
    'Kräuter', 'Thymian', 'Rosmarin',
  ], en: [
    'Lettuce', 'Spinach', 'Parsley', 'Basil',
  ]),
  (ShoppingShelf.bakery, ShoppingItemIcon.bread, de: [
    'Brot', 'Vollkornbrot', 'Toastbrot', 'Baguette', 'Ciabatta',
    'Knäckebrot', 'Wraps', 'Tortillas', 'Fladenbrot',
  ], en: [
    'Toast', 'Bread', 'Toast bread', 'Baguette', 'Ciabatta', 'Wraps',
    'Tortillas',
  ]),
  (ShoppingShelf.bakery, ShoppingItemIcon.pastry, de: [
    'Brötchen', 'Semmeln', 'Croissants', 'Croissant', 'Brezeln', 'Brezel',
    'Laugenbrezel',
  ], en: [
    'Rolls', 'Bagels', 'Croissants', 'Croissant',
  ]),
  (ShoppingShelf.bakery, ShoppingItemIcon.cake, de: [
    'Kuchen', 'Torte', 'Muffins', 'Donuts',
  ], en: [
    'Cake', 'Muffins', 'Donuts',
  ]),
  (ShoppingShelf.meatFish, ShoppingItemIcon.meat, de: [
    'Hackfleisch', 'Hack', 'Rinderhack', 'Fleisch', 'Hähnchen',
    'Hähnchenbrust', 'Hühnchen', 'Putenbrust', 'Pute', 'Steak', 'Steaks',
    'Schnitzel', 'Rindfleisch', 'Schweinefleisch', 'Gulasch', 'Würstchen',
    'Wurst', 'Bratwurst', 'Salami', 'Schinken', 'Speck', 'Aufschnitt',
  ], en: [
    'Chicken', 'Beef', 'Mince', 'Ham', 'Bacon', 'Sausages', 'Steak',
    'Steaks',
  ]),
  (ShoppingShelf.meatFish, ShoppingItemIcon.fish, de: [
    'Lachs', 'Fisch', 'Thunfisch', 'Garnelen', 'Forelle', 'Kabeljau',
    'Hering',
  ], en: [
    'Salmon', 'Fish', 'Shrimps', 'Tuna',
  ]),
  (ShoppingShelf.chilled, ShoppingItemIcon.milk, de: [
    'Milch', 'Vollmilch', 'Hafermilch', 'Mandelmilch', 'Sojamilch',
    'Buttermilch', 'Sahne', 'Schlagsahne', 'Kefir',
  ], en: [
    'Milk', 'Cream', 'Kefir',
  ]),
  (ShoppingShelf.chilled, ShoppingItemIcon.egg, de: [
    'Eier', 'Ei',
  ], en: [
    'Eggs',
  ]),
  (ShoppingShelf.chilled, ShoppingItemIcon.dairy, de: [
    'Butter', 'Käse', 'Margarine', 'Gouda', 'Mozzarella', 'Feta', 'Parmesan',
    'Frischkäse', 'Hüttenkäse', 'Quark', 'Magerquark', 'Joghurt', 'Jogurt',
    'Skyr', 'Schmand', 'Saure Sahne', 'Crème fraîche', 'Pudding', 'Tofu',
    'Hummus',
  ], en: [
    'Cheese', 'Yogurt', 'Yoghurt', 'Gouda', 'Mozzarella', 'Feta', 'Parmesan',
    'Skyr', 'Tofu', 'Hummus',
  ]),
  (ShoppingShelf.frozen, ShoppingItemIcon.frozen, de: [
    'Tiefkühlgemüse', 'Erbsen', 'Pommes', 'Fischstäbchen', 'Tiefkühlbeeren',
    'Eiswürfel', 'Nuggets', 'Chicken Nuggets', 'Kroketten', 'Rahmspinat',
  ], en: [
    'Frozen peas', 'Fries',
  ]),
  (ShoppingShelf.frozen, ShoppingItemIcon.iceCream, de: [
    'Eis',
  ], en: [
    'Ice cream',
  ]),
  (ShoppingShelf.frozen, ShoppingItemIcon.pizza, de: [
    'Pizza', 'Tiefkühlpizza',
  ], en: [
    'Pizza',
  ]),
  (ShoppingShelf.pantry, ShoppingItemIcon.pasta, de: [
    'Nudeln', 'Spaghetti', 'Pasta', 'Penne', 'Fusilli', 'Lasagne', 'Gnocchi',
  ], en: [
    'Noodles', 'Spaghetti', 'Pasta', 'Penne', 'Fusilli', 'Lasagne',
    'Gnocchi',
  ]),
  (ShoppingShelf.pantry, ShoppingItemIcon.grain, de: [
    'Reis', 'Haferflocken', 'Basmatireis', 'Müsli', 'Cornflakes', 'Mehl',
    'Couscous', 'Bulgur', 'Quinoa', 'Linsen', 'Kichererbsen', 'Bohnen',
    'Grieß', 'Paniermehl', 'Nüsse', 'Mandeln', 'Walnüsse', 'Erdnüsse',
  ], en: [
    'Rice', 'Oats', 'Flour', 'Lentils', 'Nuts', 'Couscous', 'Bulgur',
    'Quinoa',
  ]),
  (ShoppingShelf.pantry, ShoppingItemIcon.can, de: [
    'Gehackte Tomaten', 'Passierte Tomaten', 'Tomatenmark', 'Dosentomaten',
    'Kokosmilch', 'Brühe', 'Gemüsebrühe', 'Suppe', 'Fertigsuppe',
    'Instantsuppe', 'Ravioli', 'Marmelade', 'Konfitüre', 'Honig',
    'Nutella', 'Erdnussbutter', 'Tahini', 'Zucker', 'Backpulver', 'Hefe',
    'Vanillezucker',
  ], en: [
    'Canned tomatoes', 'Jam', 'Honey', 'Sugar',
  ]),
  (ShoppingShelf.pantry, ShoppingItemIcon.spice, de: [
    'Olivenöl', 'Salz', 'Pfeffer', 'Gewürze', 'Kreuzkümmel', 'Paprikapulver',
    'Curry', 'Zimt', 'Oregano', 'Öl', 'Rapsöl', 'Sonnenblumenöl', 'Essig',
    'Balsamico', 'Senf', 'Ketchup', 'Mayonnaise', 'Mayo', 'Sojasoße',
    'Sojasauce', 'Pesto',
  ], en: [
    'Salt', 'Olive oil', 'Oil', 'Vinegar', 'Mustard', 'Curry', 'Oregano',
    'Ketchup', 'Mayonnaise', 'Pesto',
  ]),
  (ShoppingShelf.drinks, ShoppingItemIcon.coffee, de: [
    'Kaffee', 'Kaffeebohnen', 'Espresso', 'Kaffeepads', 'Kapseln',
  ], en: [
    'Coffee', 'Espresso',
  ]),
  (ShoppingShelf.drinks, ShoppingItemIcon.tea, de: [
    'Tee', 'Grüntee',
  ], en: [
    'Tea',
  ]),
  (ShoppingShelf.drinks, ShoppingItemIcon.water, de: [
    'Mineralwasser', 'Wasser', 'Sprudel',
  ], en: [
    'Water',
  ]),
  (ShoppingShelf.drinks, ShoppingItemIcon.juice, de: [
    'Orangensaft', 'Saft', 'Apfelsaft', 'Apfelschorle', 'Schorle', 'Cola',
    'Limo', 'Limonade', 'Eistee',
  ], en: [
    'Juice', 'Lemonade', 'Cola',
  ]),
  (ShoppingShelf.drinks, ShoppingItemIcon.beer, de: [
    'Bier', 'Radler',
  ], en: [
    'Beer',
  ]),
  (ShoppingShelf.drinks, ShoppingItemIcon.wine, de: [
    'Wein', 'Rotwein', 'Weißwein', 'Sekt', 'Prosecco', 'Wodka', 'Gin',
  ], en: [
    'Wine', 'Gin',
  ]),
  (ShoppingShelf.sweets, ShoppingItemIcon.sweets, de: [
    'Schokolade', 'Süßigkeiten', 'Gummibärchen', 'Bonbons', 'Proteinriegel',
    'Riegel', 'Müsliriegel',
  ], en: [
    'Chocolate', 'Sweets',
  ]),
  (ShoppingShelf.sweets, ShoppingItemIcon.snack, de: [
    'Kekse', 'Chips', 'Salzstangen', 'Popcorn', 'Cracker', 'Bananenchips',
  ], en: [
    'Cookies', 'Crisps', 'Chips', 'Popcorn', 'Cracker',
  ]),
  (ShoppingShelf.drugstore, ShoppingItemIcon.care, de: [
    'Zahnpasta', 'Duschgel', 'Shampoo', 'Zahnbürste', 'Seife', 'Deo',
    'Deodorant', 'Creme', 'Sonnencreme', 'Rasierer', 'Tampons', 'Binden',
    'Wattepads', 'Taschentücher',
  ], en: [
    'Toothpaste', 'Soap', 'Shampoo', 'Tampons',
  ]),
  (ShoppingShelf.drugstore, ShoppingItemIcon.medicine, de: [
    'Pflaster', 'Tabletten', 'Medikamente', 'Ibuprofen', 'Paracetamol',
    'Vitamine',
  ], en: [
    'Medicine', 'Ibuprofen', 'Paracetamol',
  ]),
  (ShoppingShelf.drugstore, ShoppingItemIcon.baby, de: [
    'Windeln', 'Feuchttücher', 'Babynahrung',
  ], en: [
    'Diapers',
  ]),
  (ShoppingShelf.household, ShoppingItemIcon.cleaning, de: [
    'Spülmittel', 'Toilettenpapier', 'Küchenrolle', 'Müllbeutel', 'Spültabs',
    'Reiniger', 'Allzweckreiniger', 'Klopapier', 'Schwämme', 'Alufolie',
    'Frischhaltefolie', 'Backpapier', 'Batterien', 'Kerzen',
  ], en: [
    'Dish soap', 'Toilet paper', 'Paper towels', 'Bin bags',
  ]),
  (ShoppingShelf.household, ShoppingItemIcon.laundry, de: [
    'Waschmittel', 'Weichspüler',
  ], en: [
    'Laundry detergent',
  ]),
  (ShoppingShelf.household, ShoppingItemIcon.pet, de: [
    'Katzenfutter', 'Hundefutter', 'Katzenstreu',
  ], en: [
    'Cat food', 'Dog food',
  ]),
  (ShoppingShelf.household, ShoppingItemIcon.flower, de: [
    'Blumen', 'Blumenerde',
  ], en: [
    'Flowers',
  ]),
];
