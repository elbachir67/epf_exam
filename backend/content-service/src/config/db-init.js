const mongoose = require("mongoose");
const Category = require("../models/category.model");
const logger = require("../utils/logger");

const initializeDatabase = async () => {
  try {
    logger.info("Checking database initialization...");

    const count = await Category.countDocuments();
    logger.info(`Found ${count} categories in database`);

    if (count === 0) {
      logger.info("No categories found. Initializing default categories...");

      const defaultCategories = [
        {
          name: "Engineering",
          description: "Questions about engineering subjects and practices",
          color: "#1976D2",
          icon: "engineering",
          isActive: true,
        },
        {
          name: "Computer Science",
          description: "Programming, algorithms, software development",
          color: "#388E3C",
          icon: "computer",
          isActive: true,
        },
        {
          name: "Business",
          description: "Business management, entrepreneurship, economics",
          color: "#F57C00",
          icon: "business",
          isActive: true,
        },
        {
          name: "Mathematics",
          description: "Pure and applied mathematics questions",
          color: "#7B1FA2",
          icon: "calculate",
          isActive: true,
        },
        {
          name: "Sciences",
          description: "Physics, chemistry, biology and other sciences",
          color: "#C62828",
          icon: "science",
          isActive: true,
        },
        {
          name: "General",
          description: "General questions about EPF Africa and student life",
          color: "#455A64",
          icon: "school",
          isActive: true,
        },
      ];

      const insertedCategories = await Category.insertMany(defaultCategories);
      logger.info(
        `✅ Successfully created ${insertedCategories.length} default categories`
      );

      // Log each category
      insertedCategories.forEach(cat => {
        logger.info(`  - ${cat.name} (${cat._id})`);
      });
    } else {
      logger.info(`✅ Categories already initialized (${count} found)`);
    }
  } catch (error) {
    logger.error("❌ Error initializing database:", error);
    throw error;
  }
};

module.exports = initializeDatabase;
