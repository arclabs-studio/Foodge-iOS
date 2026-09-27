//
//  DishCatalogue+Dishes.swift
//  Foodge
//
//  Created by ARC Labs Studio on 20/09/2026.
//

import Foundation

extension DishCatalogue {
    static let burgers = Dish(
        id: "dish.burgers",
        family: .burgers,
        variants: [
            DishVariant(
                id: "dish.burgers.beef",
                nameKey: "Beef burger",
                ingredients: [.beefPatty, .burgerBun, .lettuce, .tomato, .onion, .mayonnaise],
                diets: [.omnivore],
                convenience: [.quick],
                calorieReferenceID: nil
            ),
            DishVariant(
                id: "dish.burgers.halloumi",
                nameKey: "Halloumi burger",
                ingredients: [.halloumi, .burgerBun, .lettuce, .tomato, .onion],
                diets: [.omnivore, .pescatarian, .vegetarian],
                convenience: [.quick],
                calorieReferenceID: nil
            ),
            DishVariant(
                id: "dish.burgers.blackBean",
                nameKey: "Black bean burger",
                ingredients: [.blackBeans, .burgerBun, .lettuce, .tomato, .avocado],
                diets: [.omnivore, .pescatarian, .vegetarian, .vegan],
                convenience: [.quick],
                calorieReferenceID: nil
            )
        ]
    )

    static let pizza = Dish(
        id: "dish.pizza",
        family: .pizza,
        variants: [
            DishVariant(
                id: "dish.pizza.margherita",
                nameKey: "Margherita pizza",
                ingredients: [.pizzaBase, .tomatoSauce, .mozzarella, .basil],
                diets: [.omnivore, .pescatarian, .vegetarian],
                convenience: [.quick, .leftoversFriendly],
                calorieReferenceID: nil
            ),
            DishVariant(
                id: "dish.pizza.tuna",
                nameKey: "Tuna and onion pizza",
                ingredients: [.pizzaBase, .tomatoSauce, .mozzarella, .tuna, .onion],
                diets: [.omnivore, .pescatarian],
                convenience: [.quick, .leftoversFriendly],
                calorieReferenceID: nil
            ),
            DishVariant(
                id: "dish.pizza.vegetable",
                nameKey: "Vegetable pizza",
                ingredients: [.pizzaBase, .tomatoSauce, .mushroom, .bellPepper, .olive, .onion],
                diets: [.omnivore, .pescatarian, .vegetarian, .vegan],
                convenience: [.quick, .leftoversFriendly],
                calorieReferenceID: nil
            )
        ]
    )

    static let tacos = Dish(
        id: "dish.tacos",
        family: .tacos,
        variants: [
            DishVariant(
                id: "dish.tacos.beef",
                nameKey: "Beef tacos",
                ingredients: [.cornTortilla, .beefMince, .onion, .tomato, .coriander, .lime],
                diets: [.omnivore],
                convenience: [.quick, .onePan],
                calorieReferenceID: nil
            ),
            DishVariant(
                id: "dish.tacos.prawn",
                nameKey: "Prawn tacos",
                ingredients: [.cornTortilla, .prawns, .lettuce, .lime, .coriander, .mayonnaise],
                diets: [.omnivore, .pescatarian],
                convenience: [.quick],
                calorieReferenceID: nil
            ),
            DishVariant(
                id: "dish.tacos.blackBean",
                nameKey: "Black bean tacos",
                ingredients: [.cornTortilla, .blackBeans, .avocado, .tomato, .coriander, .lime],
                diets: [.omnivore, .pescatarian, .vegetarian, .vegan],
                convenience: [.quick, .onePan],
                calorieReferenceID: nil
            )
        ]
    )

    static let riceBowls = Dish(
        id: "dish.riceBowls",
        family: .riceBowls,
        variants: [
            DishVariant(
                id: "dish.riceBowls.chicken",
                nameKey: "Chicken rice bowl",
                ingredients: [.rice, .chickenBreast, .carrot, .bellPepper, .soySauce],
                diets: [.omnivore],
                convenience: [.onePan, .leftoversFriendly],
                calorieReferenceID: nil
            ),
            DishVariant(
                id: "dish.riceBowls.salmon",
                nameKey: "Salmon rice bowl",
                ingredients: [.rice, .salmon, .cucumber, .avocado, .soySauce],
                diets: [.omnivore, .pescatarian],
                convenience: [.quick, .leftoversFriendly],
                calorieReferenceID: nil
            ),
            DishVariant(
                id: "dish.riceBowls.tofu",
                nameKey: "Tofu rice bowl",
                ingredients: [.rice, .tofu, .carrot, .spinach, .soySauce],
                diets: [.omnivore, .pescatarian, .vegetarian, .vegan],
                convenience: [.onePan, .leftoversFriendly],
                calorieReferenceID: nil
            )
        ]
    )

    static let tortilla = Dish(
        id: "dish.tortilla",
        family: .tortilla,
        variants: [
            DishVariant(
                id: "dish.tortilla.potato",
                nameKey: "Potato tortilla",
                ingredients: [.egg, .potato, .onion, .oliveOil],
                diets: [.omnivore, .pescatarian, .vegetarian],
                convenience: [.onePan, .leftoversFriendly],
                calorieReferenceID: nil
            ),
            DishVariant(
                id: "dish.tortilla.spinach",
                nameKey: "Spinach tortilla",
                ingredients: [.egg, .potato, .spinach, .oliveOil],
                diets: [.omnivore, .pescatarian, .vegetarian],
                convenience: [.onePan, .leftoversFriendly],
                calorieReferenceID: nil
            ),
            DishVariant(
                id: "dish.tortilla.chorizo",
                nameKey: "Chorizo tortilla",
                ingredients: [.egg, .potato, .chorizo, .onion, .oliveOil],
                diets: [.omnivore],
                convenience: [.onePan, .leftoversFriendly],
                calorieReferenceID: nil
            )
        ]
    )

    static let pasta = Dish(
        id: "dish.pasta",
        family: .pasta,
        variants: [
            DishVariant(
                id: "dish.pasta.bolognese",
                nameKey: "Pasta bolognese",
                ingredients: [.pasta, .beefMince, .tomatoSauce, .onion, .garlic, .parmesan],
                diets: [.omnivore],
                convenience: [.leftoversFriendly],
                calorieReferenceID: nil
            ),
            DishVariant(
                id: "dish.pasta.pesto",
                nameKey: "Pasta with pesto",
                ingredients: [.pasta, .basil, .parmesan, .garlic, .oliveOil],
                diets: [.omnivore, .pescatarian, .vegetarian],
                convenience: [.quick, .leftoversFriendly],
                calorieReferenceID: nil
            ),
            DishVariant(
                id: "dish.pasta.arrabbiata",
                nameKey: "Pasta arrabbiata",
                ingredients: [.pasta, .tomatoSauce, .garlic, .oliveOil],
                diets: [.omnivore, .pescatarian, .vegetarian, .vegan],
                convenience: [.quick, .onePan, .leftoversFriendly],
                calorieReferenceID: nil
            )
        ]
    )

    static let lentilSalad = Dish(
        id: "dish.lentilSalad",
        family: .lentilSalad,
        variants: [
            DishVariant(
                id: "dish.lentilSalad.tomato",
                nameKey: "Lentil and tomato salad",
                ingredients: [.cookedLentils, .tomato, .cucumber, .onion, .oliveOil],
                diets: [.omnivore, .pescatarian, .vegetarian, .vegan],
                convenience: [.noCook, .quick, .leftoversFriendly],
                calorieReferenceID: nil
            ),
            DishVariant(
                id: "dish.lentilSalad.feta",
                nameKey: "Lentil and feta salad",
                ingredients: [.cookedLentils, .feta, .cucumber, .tomato, .oliveOil],
                diets: [.omnivore, .pescatarian, .vegetarian],
                convenience: [.noCook, .quick],
                calorieReferenceID: nil
            ),
            DishVariant(
                id: "dish.lentilSalad.tuna",
                nameKey: "Lentil and tuna salad",
                ingredients: [.cookedLentils, .tuna, .onion, .tomato, .oliveOil],
                diets: [.omnivore, .pescatarian],
                convenience: [.noCook, .quick],
                calorieReferenceID: nil
            )
        ]
    )

    static let vegetableSoup = Dish(
        id: "dish.vegetableSoup",
        family: .vegetableSoup,
        variants: [
            DishVariant(
                id: "dish.vegetableSoup.garden",
                nameKey: "Garden vegetable soup with toast",
                ingredients: [.carrot, .potato, .onion, .garlic, .oliveOil, .bread],
                diets: [.omnivore, .pescatarian, .vegetarian, .vegan],
                convenience: [.onePan, .leftoversFriendly],
                calorieReferenceID: nil
            ),
            DishVariant(
                id: "dish.vegetableSoup.tomato",
                nameKey: "Tomato soup with toast",
                ingredients: [.tomato, .garlic, .oliveOil, .basil, .bread],
                diets: [.omnivore, .pescatarian, .vegetarian, .vegan],
                convenience: [.onePan, .leftoversFriendly],
                calorieReferenceID: nil
            ),
            DishVariant(
                id: "dish.vegetableSoup.chickpea",
                nameKey: "Chickpea and spinach soup",
                ingredients: [.chickpeas, .spinach, .garlic, .onion, .oliveOil],
                diets: [.omnivore, .pescatarian, .vegetarian, .vegan],
                convenience: [.onePan, .leftoversFriendly],
                calorieReferenceID: nil
            )
        ]
    )

    static let vegetableWraps = Dish(
        id: "dish.vegetableWraps",
        family: .vegetableWraps,
        variants: [
            DishVariant(
                id: "dish.vegetableWraps.hummus",
                nameKey: "Hummus and vegetable wrap",
                ingredients: [.wheatWrap, .hummus, .cucumber, .carrot, .spinach],
                diets: [.omnivore, .pescatarian, .vegetarian, .vegan],
                convenience: [.noCook, .quick],
                calorieReferenceID: nil
            ),
            DishVariant(
                id: "dish.vegetableWraps.falafel",
                nameKey: "Falafel wrap",
                ingredients: [.wheatWrap, .falafel, .hummus, .tomato, .lettuce, .onion],
                diets: [.omnivore, .pescatarian, .vegetarian, .vegan],
                convenience: [.quick],
                calorieReferenceID: nil
            ),
            DishVariant(
                id: "dish.vegetableWraps.feta",
                nameKey: "Feta and roasted pepper wrap",
                ingredients: [.wheatWrap, .feta, .bellPepper, .spinach, .oliveOil],
                diets: [.omnivore, .pescatarian, .vegetarian],
                convenience: [.quick],
                calorieReferenceID: nil
            )
        ]
    )
}
