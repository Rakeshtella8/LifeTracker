import Foundation

struct Quote {
    let text: String
    let author: String
}

class QuoteProvider {
    private static var shownQuotes: Set<Int> = []
    private static let quotes: [Quote] = [
        // General Motivational Quotes
        Quote(text: "The secret of getting ahead is getting started.", author: "Mark Twain"),
        Quote(text: "The best way to predict the future is to create it.", author: "Peter Drucker"),
        Quote(text: "Well done is better than well said.", author: "Benjamin Franklin"),
        Quote(text: "A journey of a thousand miles begins with a single step.", author: "Lao Tzu"),
        Quote(text: "Little by little, one travels far.", author: "J.R.R. Tolkien"),
        Quote(text: "No one can whistle a symphony. It takes a whole orchestra to play it.", author: "H.E. Luccock"),
        Quote(text: "A book is like a garden carried in the pocket.", author: "Chinese Proverb"),
        Quote(text: "If you want to go fast, go alone. If you want to go far, go together.", author: "African Proverb"),
        Quote(text: "The best time to plant a tree was 20 years ago. The second best time is now.", author: "Chinese Proverb"),
        Quote(text: "Courage is not the absence of fear, but the triumph over it.", author: "Nelson Mandela"),
        Quote(text: "Success is not final, failure is not fatal: it is the courage to continue that counts.", author: "Winston Churchill"),
        Quote(text: "The only way to do great work is to love what you do.", author: "Steve Jobs"),
        Quote(text: "Don't watch the clock; do what it does. Keep going.", author: "Sam Levenson"),
        Quote(text: "The future belongs to those who believe in the beauty of their dreams.", author: "Eleanor Roosevelt"),
        Quote(text: "It always seems impossible until it's done.", author: "Nelson Mandela"),
        
        // Indian Proverbs and Wisdom
        Quote(text: "You reap what you sow.", author: "Indian Proverb"),
        Quote(text: "A single tree does not make a forest.", author: "Indian Proverb"),
        Quote(text: "Wisdom is wealth.", author: "Swahili Proverb"),
        Quote(text: "A diamond with a flaw is worth more than a pebble without imperfections.", author: "Indian Proverb"),
        Quote(text: "A man is not honest simply because he never had a chance to steal.", author: "Indian Proverb"),
        Quote(text: "Knowledge is like a garden; if it is not cultivated, it cannot be harvested.", author: "Indian Proverb"),
        Quote(text: "The mind is like water. When it's turbulent, it's difficult to see. When it's calm, everything becomes clear.", author: "Indian Proverb"),
        Quote(text: "As you think, so you become.", author: "Indian Proverb"),
        Quote(text: "The greatest meditation is a mind that lets go.", author: "Indian Proverb"),
        Quote(text: "Happiness is not something ready-made. It comes from your own actions.", author: "Dalai Lama"),
        Quote(text: "Peace comes from within. Do not seek it without.", author: "Buddha"),
        Quote(text: "Three things cannot be long hidden: the sun, the moon, and the truth.", author: "Buddha"),
        Quote(text: "Health is the greatest gift, contentment the greatest wealth, faithfulness the best relationship.", author: "Buddha"),
        Quote(text: "The way is not in the sky. The way is in the heart.", author: "Buddha"),
        Quote(text: "Just as a candle cannot burn without fire, men cannot live without a spiritual life.", author: "Buddha"),
        Quote(text: "Your work is to discover your world and then with all your heart give yourself to it.", author: "Buddha"),
        Quote(text: "The mind is everything. What you think you become.", author: "Buddha"),
        Quote(text: "To keep the body in good health is a duty... otherwise we shall not be able to keep our mind strong and clear.", author: "Buddha"),
        Quote(text: "Thousands of candles can be lit from a single candle, and the life of the candle will not be shortened. Happiness never decreases by being shared.", author: "Buddha"),
        // Add 100+ more unique quotes for demonstration
        Quote(text: "You miss 100% of the shots you don't take.", author: "Wayne Gretzky"),
        Quote(text: "Act as if what you do makes a difference. It does.", author: "William James"),
        Quote(text: "What you get by achieving your goals is not as important as what you become by achieving your goals.", author: "Zig Ziglar"),
        Quote(text: "Believe you can and you're halfway there.", author: "Theodore Roosevelt"),
        Quote(text: "When you have a dream, you've got to grab it and never let go.", author: "Carol Burnett"),
        Quote(text: "I can't change the direction of the wind, but I can adjust my sails to always reach my destination.", author: "Jimmy Dean"),
        Quote(text: "No matter what you're going through, there's a light at the end of the tunnel.", author: "Demi Lovato"),
        Quote(text: "It is our attitude at the beginning of a difficult task which, more than anything else, will affect its successful outcome.", author: "William James"),
        Quote(text: "Life is like riding a bicycle. To keep your balance, you must keep moving.", author: "Albert Einstein"),
        Quote(text: "Just one small positive thought in the morning can change your whole day.", author: "Dalai Lama"),
        // ... (add hundreds more as needed)
    ]
    
    static func getRandomQuote() -> Quote {
        if shownQuotes.count == quotes.count {
            shownQuotes.removeAll()
        }
        var idx: Int
        repeat {
            idx = Int.random(in: 0..<quotes.count)
        } while shownQuotes.contains(idx) && shownQuotes.count < quotes.count
        shownQuotes.insert(idx)
        return quotes[idx]
    }
} 