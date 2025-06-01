class Food {
  final int id;
  final String title;
  final String image;
  final String imageType;
  final int readyInMinutes;
  final int servings;
  final String sourceUrl;
  final String summary;
  final List<Ingredient> ingredients;
  final String instructions;
  final bool vegetarian;
  final bool vegan;
  final bool glutenFree;
  final bool dairyFree;
  final int preparationMinutes;
  final int cookingMinutes;
  final double healthScore;
  final List<Instruction> analyzedInstructions;

  Food({
    required this.id,
    required this.title,
    required this.image,
    required this.imageType,
    required this.readyInMinutes,
    required this.servings,
    required this.sourceUrl,
    this.summary = '',
    this.ingredients = const [],
    this.instructions = '',
    this.vegetarian = false,
    this.vegan = false,
    this.glutenFree = false,
    this.dairyFree = false,
    this.preparationMinutes = 0,
    this.cookingMinutes = 0,
    this.healthScore = 0,
    this.analyzedInstructions = const [],
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'],
      title: json['title'],
      image: json['image'],
      imageType: json['imageType'],
      readyInMinutes: json['readyInMinutes'] ?? 0,
      servings: json['servings'] ?? 1,
      sourceUrl: json['sourceUrl'] ?? '',
      summary: json['summary'] ?? '',
      ingredients:
          json['extendedIngredients'] != null
              ? List<Ingredient>.from(
                json['extendedIngredients'].map((x) => Ingredient.fromJson(x)),
              )
              : [],
      instructions: json['instructions'] ?? '',
      vegetarian: json['vegetarian'] ?? false,
      vegan: json['vegan'] ?? false,
      glutenFree: json['glutenFree'] ?? false,
      dairyFree: json['dairyFree'] ?? false,
      preparationMinutes: json['preparationMinutes'] ?? 0,
      cookingMinutes: json['cookingMinutes'] ?? 0,
      healthScore: (json['healthScore'] ?? 0).toDouble(),
      analyzedInstructions:
          json['analyzedInstructions'] != null
              ? List<Instruction>.from(
                json['analyzedInstructions'].map(
                  (x) => Instruction.fromJson(x),
                ),
              )
              : [],
    );
  }
}

class Ingredient {
  final int id;
  final String name;
  final double amount;
  final String unit;
  final String image;
  final String original;

  Ingredient({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
    required this.image,
    required this.original,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      image: json['image'] ?? '',
      original: json['original'] ?? '',
    );
  }
}

class FoodSearchResponse {
  final List<Food> results;
  final int offset;
  final int number;
  final int totalResults;

  FoodSearchResponse({
    required this.results,
    required this.offset,
    required this.number,
    required this.totalResults,
  });

  factory FoodSearchResponse.fromJson(Map<String, dynamic> json) {
    return FoodSearchResponse(
      results:
          (json['results'] as List).map((item) => Food.fromJson(item)).toList(),
      offset: json['offset'] ?? 0,
      number: json['number'] ?? 0,
      totalResults: json['totalResults'] ?? 0,
    );
  }
}

class Instruction {
  final String name;
  final List<InstructionStep> steps;

  Instruction({required this.name, required this.steps});

  factory Instruction.fromJson(Map<String, dynamic> json) {
    return Instruction(
      name: json['name'] ?? '',
      steps:
          json['steps'] != null
              ? List<InstructionStep>.from(
                json['steps'].map((x) => InstructionStep.fromJson(x)),
              )
              : [],
    );
  }
}

class InstructionStep {
  final int number;
  final String step;
  final List<IngredientInStep> ingredients;
  final List<Equipment> equipment;
  final StepLength? length;

  InstructionStep({
    required this.number,
    required this.step,
    required this.ingredients,
    required this.equipment,
    this.length,
  });

  factory InstructionStep.fromJson(Map<String, dynamic> json) {
    return InstructionStep(
      number: json['number'] ?? 0,
      step: json['step'] ?? '',
      ingredients:
          json['ingredients'] != null
              ? List<IngredientInStep>.from(
                json['ingredients'].map((x) => IngredientInStep.fromJson(x)),
              )
              : [],
      equipment:
          json['equipment'] != null
              ? List<Equipment>.from(
                json['equipment'].map((x) => Equipment.fromJson(x)),
              )
              : [],
      length:
          json['length'] != null ? StepLength.fromJson(json['length']) : null,
    );
  }
}

class IngredientInStep {
  final int id;
  final String name;
  final String localizedName;
  final String image;

  IngredientInStep({
    required this.id,
    required this.name,
    required this.localizedName,
    required this.image,
  });

  factory IngredientInStep.fromJson(Map<String, dynamic> json) {
    return IngredientInStep(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      localizedName: json['localizedName'] ?? '',
      image: json['image'] ?? '',
    );
  }
}

class Equipment {
  final int id;
  final String name;
  final String localizedName;
  final String image;

  Equipment({
    required this.id,
    required this.name,
    required this.localizedName,
    required this.image,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      localizedName: json['localizedName'] ?? '',
      image: json['image'] ?? '',
    );
  }
}

class StepLength {
  final int number;
  final String unit;

  StepLength({required this.number, required this.unit});

  factory StepLength.fromJson(Map<String, dynamic> json) {
    return StepLength(number: json['number'] ?? 0, unit: json['unit'] ?? '');
  }
}
