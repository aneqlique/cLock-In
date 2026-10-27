// Name/tint/icon of a user's category, copied onto posts so the feed can show it
const categorySnapshot = (user, key) => {
  const category = (user.categories || []).find((c) => c.key === key);
  return {
    categoryLabel: category ? category.name : '',
    categoryColor: category ? category.color : undefined,
    categoryIcon: category ? category.icon : '',
  };
};

module.exports = { categorySnapshot };
