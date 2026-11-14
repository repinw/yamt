// The catalog is data; one name per line would only make it longer.
// dart format off
import 'package:yamt/features/shoppinglist/domain/shopping_shelf.dart';

/// The products the app knows from the start, by shelf and picture. The first
/// name of a group is the one offered as a suggestion.
const shoppingCatalogGroups = <(ShoppingShelf, ShoppingItemIcon, List<String>)>[
  (ShoppingShelf.produce, ShoppingItemIcon.fruit, [
    'Äpfel', 'Apfel', 'Bananen', 'Banane', 'Birnen', 'Birne', 'Orangen',
    'Orange', 'Mandarinen', 'Mandarine', 'Clementinen', 'Zitronen', 'Zitrone',
    'Limetten', 'Limette', 'Weintrauben', 'Trauben', 'Erdbeeren', 'Himbeeren',
    'Heidelbeeren', 'Blaubeeren', 'Beeren', 'Kiwi', 'Mango', 'Ananas',
    'Melone', 'Wassermelone', 'Pfirsiche', 'Pfirsich', 'Nektarinen',
    'Pflaumen', 'Kirschen', 'Avocado', 'Avocados', 'Granatapfel', 'Datteln',
    'Feigen', 'Obst', 'Apples', 'Apple', 'Bananas', 'Banana', 'Lemon', 'Lime',
    'Grapes', 'Strawberries', 'Blueberries', 'Pear',
  ]),
  (ShoppingShelf.produce, ShoppingItemIcon.vegetable, [
    'Tomaten', 'Tomate', 'Gurke', 'Gurken', 'Paprika', 'Zwiebeln', 'Zwiebel',
    'Knoblauch', 'Kartoffeln', 'Kartoffel', 'Karotten', 'Karotte', 'Möhren',
    'Möhre', 'Zucchini', 'Aubergine', 'Auberginen', 'Brokkoli', 'Blumenkohl',
    'Kohl', 'Rotkohl', 'Weißkohl', 'Kohlrabi', 'Lauch', 'Porree', 'Sellerie',
    'Spargel', 'Pilze', 'Champignons', 'Mais', 'Kürbis', 'Süßkartoffeln',
    'Süßkartoffel', 'Ingwer', 'Radieschen', 'Rote Bete', 'Fenchel',
    'Rosenkohl', 'Frühlingszwiebeln', 'Schalotten', 'Chili', 'Gemüse',
    'Tomatoes', 'Tomato', 'Cucumber', 'Onions', 'Onion', 'Garlic', 'Potatoes',
    'Carrots', 'Pepper', 'Mushrooms', 'Ginger',
  ]),
  (ShoppingShelf.produce, ShoppingItemIcon.herb, [
    'Salat', 'Kopfsalat', 'Eisbergsalat', 'Rucola', 'Feldsalat', 'Spinat',
    'Petersilie', 'Basilikum', 'Schnittlauch', 'Koriander', 'Minze', 'Dill',
    'Kräuter', 'Thymian', 'Rosmarin', 'Lettuce', 'Spinach', 'Parsley', 'Basil',
  ]),
  (ShoppingShelf.bakery, ShoppingItemIcon.bread, [
    'Brot', 'Vollkornbrot', 'Toast', 'Toastbrot', 'Baguette', 'Ciabatta',
    'Knäckebrot', 'Wraps', 'Tortillas', 'Fladenbrot', 'Bread', 'Toast bread',
  ]),
  (ShoppingShelf.bakery, ShoppingItemIcon.pastry, [
    'Brötchen', 'Semmeln', 'Croissants', 'Croissant', 'Brezeln', 'Brezel',
    'Laugenbrezel', 'Rolls', 'Bagels',
  ]),
  (ShoppingShelf.bakery, ShoppingItemIcon.cake, [
    'Kuchen', 'Torte', 'Muffins', 'Donuts', 'Cake',
  ]),
  (ShoppingShelf.meatFish, ShoppingItemIcon.meat, [
    'Hackfleisch', 'Hack', 'Rinderhack', 'Fleisch', 'Hähnchen',
    'Hähnchenbrust', 'Hühnchen', 'Putenbrust', 'Pute', 'Steak', 'Steaks',
    'Schnitzel', 'Rindfleisch', 'Schweinefleisch', 'Gulasch', 'Würstchen',
    'Wurst', 'Bratwurst', 'Salami', 'Schinken', 'Speck', 'Aufschnitt',
    'Chicken', 'Beef', 'Mince', 'Ham', 'Bacon', 'Sausages',
  ]),
  (ShoppingShelf.meatFish, ShoppingItemIcon.fish, [
    'Lachs', 'Fisch', 'Thunfisch', 'Garnelen', 'Forelle', 'Kabeljau', 'Hering',
    'Salmon', 'Fish', 'Shrimps', 'Tuna',
  ]),
  (ShoppingShelf.chilled, ShoppingItemIcon.milk, [
    'Milch', 'Vollmilch', 'Hafermilch', 'Mandelmilch', 'Sojamilch',
    'Buttermilch', 'Sahne', 'Schlagsahne', 'Kefir', 'Milk', 'Cream',
  ]),
  (ShoppingShelf.chilled, ShoppingItemIcon.egg, ['Eier', 'Ei', 'Eggs']),
  (ShoppingShelf.chilled, ShoppingItemIcon.dairy, [
    'Butter', 'Käse', 'Margarine', 'Gouda', 'Mozzarella', 'Feta', 'Parmesan',
    'Frischkäse', 'Hüttenkäse', 'Quark', 'Magerquark', 'Joghurt', 'Jogurt',
    'Skyr', 'Schmand', 'Saure Sahne', 'Crème fraîche', 'Pudding', 'Tofu',
    'Hummus', 'Cheese', 'Yogurt', 'Yoghurt',
  ]),
  (ShoppingShelf.frozen, ShoppingItemIcon.frozen, [
    'Tiefkühlgemüse', 'Erbsen', 'Pommes', 'Fischstäbchen', 'Tiefkühlbeeren',
    'Eiswürfel', 'Frozen peas', 'Fries',
  ]),
  (ShoppingShelf.frozen, ShoppingItemIcon.iceCream, ['Eis', 'Ice cream']),
  (ShoppingShelf.frozen, ShoppingItemIcon.pizza, ['Pizza', 'Tiefkühlpizza']),
  (ShoppingShelf.pantry, ShoppingItemIcon.pasta, [
    'Nudeln', 'Spaghetti', 'Pasta', 'Penne', 'Fusilli', 'Lasagne', 'Gnocchi',
    'Noodles',
  ]),
  (ShoppingShelf.pantry, ShoppingItemIcon.grain, [
    'Reis', 'Haferflocken', 'Basmatireis', 'Müsli', 'Cornflakes', 'Mehl',
    'Couscous', 'Bulgur', 'Quinoa', 'Linsen', 'Kichererbsen', 'Bohnen',
    'Grieß', 'Paniermehl', 'Nüsse', 'Mandeln', 'Walnüsse', 'Erdnüsse',
    'Rice', 'Oats', 'Flour', 'Lentils', 'Nuts',
  ]),
  (ShoppingShelf.pantry, ShoppingItemIcon.can, [
    'Gehackte Tomaten', 'Passierte Tomaten', 'Tomatenmark', 'Dosentomaten',
    'Kokosmilch', 'Brühe', 'Gemüsebrühe', 'Marmelade', 'Konfitüre', 'Honig',
    'Nutella', 'Erdnussbutter', 'Tahini', 'Zucker', 'Backpulver', 'Hefe',
    'Vanillezucker', 'Canned tomatoes', 'Jam', 'Honey', 'Sugar',
  ]),
  (ShoppingShelf.pantry, ShoppingItemIcon.spice, [
    'Olivenöl', 'Salz', 'Pfeffer', 'Gewürze', 'Kreuzkümmel', 'Paprikapulver',
    'Curry', 'Zimt', 'Oregano', 'Öl', 'Rapsöl', 'Sonnenblumenöl', 'Essig',
    'Balsamico', 'Senf', 'Ketchup', 'Mayonnaise', 'Mayo', 'Sojasoße',
    'Sojasauce', 'Pesto', 'Salt', 'Olive oil', 'Oil', 'Vinegar', 'Mustard',
  ]),
  (ShoppingShelf.drinks, ShoppingItemIcon.coffee, [
    'Kaffee', 'Kaffeebohnen', 'Espresso', 'Kaffeepads', 'Kapseln', 'Coffee',
  ]),
  (ShoppingShelf.drinks, ShoppingItemIcon.tea, ['Tee', 'Grüntee', 'Tea']),
  (ShoppingShelf.drinks, ShoppingItemIcon.water, [
    'Mineralwasser', 'Wasser', 'Sprudel', 'Water',
  ]),
  (ShoppingShelf.drinks, ShoppingItemIcon.juice, [
    'Orangensaft', 'Saft', 'Apfelsaft', 'Apfelschorle', 'Schorle', 'Cola',
    'Limo', 'Limonade', 'Eistee', 'Juice', 'Lemonade',
  ]),
  (ShoppingShelf.drinks, ShoppingItemIcon.beer, ['Bier', 'Radler', 'Beer']),
  (ShoppingShelf.drinks, ShoppingItemIcon.wine, [
    'Wein', 'Rotwein', 'Weißwein', 'Sekt', 'Prosecco', 'Wodka', 'Gin', 'Wine',
  ]),
  (ShoppingShelf.sweets, ShoppingItemIcon.sweets, [
    'Schokolade', 'Süßigkeiten', 'Gummibärchen', 'Bonbons', 'Proteinriegel',
    'Riegel', 'Müsliriegel', 'Chocolate', 'Sweets',
  ]),
  (ShoppingShelf.sweets, ShoppingItemIcon.snack, [
    'Kekse', 'Chips', 'Salzstangen', 'Popcorn', 'Cracker', 'Bananenchips',
    'Cookies', 'Crisps',
  ]),
  (ShoppingShelf.drugstore, ShoppingItemIcon.care, [
    'Zahnpasta', 'Duschgel', 'Shampoo', 'Zahnbürste', 'Seife', 'Deo',
    'Deodorant', 'Creme', 'Sonnencreme', 'Rasierer', 'Tampons', 'Binden',
    'Wattepads', 'Taschentücher', 'Toothpaste', 'Soap',
  ]),
  (ShoppingShelf.drugstore, ShoppingItemIcon.medicine, [
    'Pflaster', 'Tabletten', 'Medikamente', 'Ibuprofen', 'Paracetamol',
    'Vitamine', 'Medicine',
  ]),
  (ShoppingShelf.drugstore, ShoppingItemIcon.baby, [
    'Windeln', 'Feuchttücher', 'Babynahrung', 'Diapers',
  ]),
  (ShoppingShelf.household, ShoppingItemIcon.cleaning, [
    'Spülmittel', 'Toilettenpapier', 'Küchenrolle', 'Müllbeutel', 'Spültabs',
    'Reiniger', 'Allzweckreiniger', 'Klopapier', 'Schwämme', 'Alufolie',
    'Frischhaltefolie', 'Backpapier', 'Batterien', 'Kerzen', 'Dish soap',
    'Toilet paper', 'Paper towels', 'Bin bags',
  ]),
  (ShoppingShelf.household, ShoppingItemIcon.laundry, [
    'Waschmittel', 'Weichspüler', 'Laundry detergent',
  ]),
  (ShoppingShelf.household, ShoppingItemIcon.pet, [
    'Katzenfutter', 'Hundefutter', 'Katzenstreu', 'Cat food', 'Dog food',
  ]),
  (ShoppingShelf.household, ShoppingItemIcon.flower, [
    'Blumen', 'Blumenerde', 'Flowers',
  ]),
];
