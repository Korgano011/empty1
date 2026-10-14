import Foundation

/// What a newcomer says on her first ride in the saucer — every one of them loves it in her own way.
struct RideLines {
    /// When the saucer comes down over the house, and once she's strapped in aboard.
    var spotSaucer, inShip: String
    /// As the machine runs: the tingle, the legs, the body, then her face.
    var tingle, legs, body, faceWarning, faceComing, faceLine: String
    /// Seeing herself in the mirror, then feeling her new head.
    var mirror, headFeel: String
}

/// An aunt (Mom's sister) who drops her little girl off after an even night so she and Mom can go clothes shopping.
struct AuntVisit {
    var aunt: String
    var cousin: String
    var age: Int
    var auntSkin, auntHair, cousinHair, auntShirt, cousinShirt: RGB
    var auntStyle, cousinStyle: HairStyle

    // The cousin
    var curious: String
    var accept: String
    var cousinRide: RideLines
    var showMoney: String
    var cousinBye: String

    // The aunt
    var hello: String
    var back: String
    var suspicious: [String]
    var scoff: String
    var auntAccept: String
    var auntRide: RideLines
    var thanks: String
    var auntBye: String

    /// The cousin's height and head size go with her age (4…8).
    var cousinHeight: Double { 88 + Double(age - 4) * 7.5 }
    var cousinHeadScale: Double { 0.168 - Double(age - 4) * 0.006 }

    static let all: [AuntVisit] = [
        AuntVisit(
            aunt: "Patty", cousin: "Lily", age: 4,
            auntSkin: RGB(r: 0.96, g: 0.80, b: 0.68), auntHair: RGB(r: 0.62, g: 0.36, b: 0.16),
            cousinHair: RGB(r: 0.78, g: 0.48, b: 0.20),
            auntShirt: RGB(r: 0.20, g: 0.60, b: 0.55), cousinShirt: RGB(r: 1.0, g: 0.62, b: 0.78),
            auntStyle: .curly, cousinStyle: .pigtails,
            curious: "Ooh! A shiny green button! Is it candy?",
            accept: "A spaceship ride? YES YES YES!",
            cousinRide: RideLines(
                spotSaucer: "A SPACESHIP! It's like my bedtime story!",
                inShip: "Hi, alien friends! I'm Lily! I'm four!",
                tingle: "Hee hee! It's like bubbles in my toes!",
                legs: "My legs are getting all squiggly-wiggly!",
                body: "My tummy is turning colors! Like a crayon!",
                faceWarning: "It's coming up to my cheeks!",
                faceComing: "Ooh, my face feels all fizzy!",
                faceLine: "Wheeeeeeeee!",
                mirror: "I'm a baby alien! I'm SO cute!",
                headFeel: "My head is big and round like a bouncy ball!"),
            showMoney: "Mommy! Mommy! I made money! It's all for you!",
            cousinBye: "Bye-bye! I want to be an alien again tomorrow!",
            hello: "Hi, sis! Want to come clothes shopping with me today? There's a big sale at the mall!",
            back: "We're back! We bought SO many clothes!",
            suspicious: ["Lily, honey… where did you get all that money?", "Girls, what have you been up to while we were gone?"],
            scoff: "A flying saucer? Oh, come on now, Lily.",
            auntAccept: "Well… all right. I'll come see this flying saucer for myself!",
            auntRide: RideLines(
                spotSaucer: "Oh my goodness — it's real! It's absolutely beautiful!",
                inShip: "A real flying saucer! I've dreamed of this since I was a little girl!",
                tingle: "Ooh, how lovely! Like a warm bubble bath!",
                legs: "My legs are changing! Oh, how exciting!",
                body: "Look at my arms! What a gorgeous color!",
                faceWarning: "Here it comes — I'm ready!",
                faceComing: "Ooh, I can feel my face changing — how wonderful!",
                faceLine: "Woo-hoooooo!",
                mirror: "Look at me! I'm a Roswell alien! I love it!",
                headFeel: "My head is so big and smooth — no more bad hair days!"),
            thanks: "A quarter for me and Lily? You girls are the best!",
            auntBye: "Thanks, sis! Best shopping day ever — and I got to be an alien!"),
        AuntVisit(
            aunt: "Joanne", cousin: "Bella", age: 5,
            auntSkin: RGB(r: 0.86, g: 0.66, b: 0.50), auntHair: RGB(r: 0.10, g: 0.08, b: 0.06),
            cousinHair: RGB(r: 0.14, g: 0.10, b: 0.07),
            auntShirt: RGB(r: 0.85, g: 0.25, b: 0.40), cousinShirt: RGB(r: 0.55, g: 0.80, b: 0.95),
            auntStyle: .bob, cousinStyle: .ponytail,
            curious: "What does this glowy green button do? Can I push it?",
            accept: "Ooh, I want to be an alien princess! Let's go!",
            cousinRide: RideLines(
                spotSaucer: "Whoa! A real flying saucer! It's so sparkly!",
                inShip: "These chairs are like a ride at the fair! I love it!",
                tingle: "Ooh, tickly tickly!",
                legs: "My legs are turning alien! Cool!",
                body: "My arms are changing color! Pretty!",
                faceWarning: "It's coming up to my face — yay!",
                faceComing: "My face feels all glowy!",
                faceLine: "Yippeeeeeee!",
                mirror: "I'm an alien princess! Look at my big eyes!",
                headFeel: "My head is so smooth, like a big egg!"),
            showMoney: "Mommy, look! I worked at a spaceship and made all this for you!",
            cousinBye: "Bye, cousins! That was the best day of my whole life!",
            hello: "Hi, sis! I need some new outfits — come shopping with me?",
            back: "Home again! I found the cutest dresses!",
            suspicious: ["Bella! Where did a five-year-old get that kind of cash?", "Okay, girls. Somebody start talking."],
            scoff: "A flying saucer… in the backyard. Sure it is, sweetie.",
            auntAccept: "Fine — if there's really a flying saucer, I want a ride!",
            auntRide: RideLines(
                spotSaucer: "Bella was telling the truth! Look at that thing!",
                inShip: "A real flying saucer! This is better than any roller coaster!",
                tingle: "Oh, that tickles! Hee hee!",
                legs: "My legs! Look at them go — this is fantastic!",
                body: "My whole body is changing! What a thrill!",
                faceWarning: "Here comes my face — I can't wait!",
                faceComing: "Ooh, it feels like a spa facial!",
                faceLine: "Wheeeeeeeeee!",
                mirror: "Would you look at that! I make a great Roswell alien!",
                headFeel: "My head is so big and round — I feel like a superstar!"),
            thanks: "A quarter of the profit? I'm buying Bella a new bike!",
            auntBye: "Thanks, everybody! Bella and I will never forget today!"),
        AuntVisit(
            aunt: "Sharon", cousin: "Zoe", age: 6,
            auntSkin: RGB(r: 0.99, g: 0.86, b: 0.76), auntHair: RGB(r: 0.95, g: 0.82, b: 0.45),
            cousinHair: RGB(r: 0.96, g: 0.85, b: 0.50),
            auntShirt: RGB(r: 0.45, g: 0.35, b: 0.80), cousinShirt: RGB(r: 0.40, g: 0.85, b: 0.45),
            auntStyle: .long, cousinStyle: .long,
            curious: "Hey! Why is this button glowing? What's it for?",
            accept: "That's the coolest thing EVER! Count me in!",
            cousinRide: RideLines(
                spotSaucer: "No way! A flying saucer! Wait till I tell my class!",
                inShip: "I'm inside a real spaceship! This is awesome!",
                tingle: "It feels like a hundred ladybugs!",
                legs: "Look, my legs are changing! So cool!",
                body: "I'm turning into an alien! This is the best!",
                faceWarning: "Here it comes — up to my face!",
                faceComing: "My face is getting all tingly!",
                faceLine: "Woo-hoooooooo!",
                mirror: "I'm a real Roswell alien! My class is going to flip!",
                headFeel: "My head is HUGE! It's like a giant gumdrop!"),
            showMoney: "Mom! Guess what? I made a whole bunch of money — for YOU!",
            cousinBye: "Bye! Can we come over again next week? PLEASE?",
            hello: "Morning, sis! There's a huge clothing sale downtown — want to come?",
            back: "We're home! We shopped till we dropped!",
            suspicious: ["Zoe, where did all this money come from?", "Hmm. You girls look awfully pleased with yourselves…"],
            scoff: "A spaceship? Zoe, you and your imagination!",
            auntAccept: "Oh, why not? Let's see this so-called flying saucer!",
            auntRide: RideLines(
                spotSaucer: "Oh my stars! It's a real, live flying saucer!",
                inShip: "I can't believe I'm on a flying saucer! How thrilling!",
                tingle: "Ooh, what a pleasant little tingle!",
                legs: "My legs are changing! This is incredible!",
                body: "My arms are turning the prettiest color!",
                faceWarning: "Oh, here comes my face — how exciting!",
                faceComing: "My face feels all warm and glowy!",
                faceLine: "Yahoooooooo!",
                mirror: "I'm a Roswell alien! I've never looked better!",
                headFeel: "My head is so big and smooth — I love it!"),
            thanks: "A quarter for Zoe and me? Thank you, girls!",
            auntBye: "Thanks, sis! Today was out of this world — literally!"),
        AuntVisit(
            aunt: "Debbie", cousin: "Ava", age: 7,
            auntSkin: RGB(r: 0.62, g: 0.42, b: 0.30), auntHair: RGB(r: 0.08, g: 0.06, b: 0.05),
            cousinHair: RGB(r: 0.10, g: 0.07, b: 0.05),
            auntShirt: RGB(r: 0.95, g: 0.60, b: 0.20), cousinShirt: RGB(r: 0.90, g: 0.35, b: 0.55),
            auntStyle: .bun, cousinStyle: .curly,
            curious: "Whoa, a glowing green button! Is this a secret?",
            accept: "I'd LOVE to come! I'm going to be the best alien ever!",
            cousinRide: RideLines(
                spotSaucer: "It's a flying saucer! It's even cooler than in the movies!",
                inShip: "Look at all the lights and buttons! I love it here!",
                tingle: "Ooh, it's like fizzy soda all over!",
                legs: "My legs are turning alien! Awesome!",
                body: "My arms are changing color! This is amazing!",
                faceWarning: "It's coming up to my face!",
                faceComing: "Ooh, my face feels so funny — in a good way!",
                faceLine: "Yaaaaaaaaay!",
                mirror: "That's ME? I'm a Roswell alien! I love it!",
                headFeel: "My head is so big — like a giant balloon!"),
            showMoney: "Mom, look what I earned today! It's all for you!",
            cousinBye: "Bye, everybody! Best sleepover-without-sleeping ever!",
            hello: "Hey, sis! Let's go clothes shopping — my treat for lunch!",
            back: "We're back! And we found shoes on sale!",
            suspicious: ["Ava, where did you get that much money?", "Something's going on here, and I want to know what!"],
            scoff: "A flying saucer? Ava, honey, there's no such thing.",
            auntAccept: "Okay, okay — show me! I'm coming along!",
            auntRide: RideLines(
                spotSaucer: "Well, I'll be! A real flying saucer!",
                inShip: "Ava, you were right! This is fantastic!",
                tingle: "Ooh, that tingle feels so nice!",
                legs: "My legs are changing! Oh, I love it!",
                body: "My arms and chest are turning color! How fun!",
                faceWarning: "Bring it on — I'm ready for my face!",
                faceComing: "Oh, my face feels like it's smiling all by itself!",
                faceLine: "Woo-hoo-hoooooo!",
                mirror: "Look at me! I'm a gorgeous Roswell alien!",
                headFeel: "My head is so big and round — what a hoot!"),
            thanks: "A quarter of the profit for Ava and me? You're too kind!",
            auntBye: "Bye, sis! Next shopping trip, we take the saucer!"),
        AuntVisit(
            aunt: "Lisa", cousin: "Chloe", age: 8,
            auntSkin: RGB(r: 0.90, g: 0.72, b: 0.56), auntHair: RGB(r: 0.72, g: 0.30, b: 0.12),
            cousinHair: RGB(r: 0.75, g: 0.32, b: 0.14),
            auntShirt: RGB(r: 0.25, g: 0.50, b: 0.90), cousinShirt: RGB(r: 0.98, g: 0.80, b: 0.25),
            auntStyle: .ponytail, cousinStyle: .ponytail,
            curious: "Hmm… a glowing green button. What happens if you press it?",
            accept: "Seriously? A trip on a flying saucer? I'm in!",
            cousinRide: RideLines(
                spotSaucer: "A flying saucer! This is SO much better than shopping!",
                inShip: "I'm on a real flying saucer! This is epic!",
                tingle: "Whoa, it's tingly — like static on a trampoline!",
                legs: "My legs are turning alien! That's so cool!",
                body: "My whole body is changing color! Awesome!",
                faceWarning: "Here it comes — my face is next!",
                faceComing: "Ooh, my face is changing! Best feeling ever!",
                faceLine: "Woooooooooo!",
                mirror: "I'm a real Roswell alien! I look awesome!",
                headFeel: "My head is so big and smooth — it's like a crystal ball!"),
            showMoney: "Mom, I made all this money today — I want you to have it!",
            cousinBye: "Bye, cousins! You have the coolest house in the world!",
            hello: "Hi, sis! I need a new wardrobe — want to come shopping with me?",
            back: "We're back! Our arms are full of bags!",
            suspicious: ["Chloe! That's a lot of money! Where did it come from?", "Girls, I'd like an explanation, please."],
            scoff: "A flying saucer, Chloe? I wasn't born yesterday.",
            auntAccept: "All right, I'll play along. Show me this flying saucer!",
            auntRide: RideLines(
                spotSaucer: "Oh my — Chloe was telling the truth! It's real!",
                inShip: "A real flying saucer! This is the most exciting day of my life!",
                tingle: "Ooh, that tingles in the nicest way!",
                legs: "My legs are changing — how amazing!",
                body: "My arms are turning color! Oh, I love this!",
                faceWarning: "My face is next — I can hardly wait!",
                faceComing: "Ooh, my face feels so fresh and bright!",
                faceLine: "Wheeee-hee-heeeee!",
                mirror: "Is that me? I'm a beautiful Roswell alien!",
                headFeel: "My head is so big and smooth — it feels marvelous!"),
            thanks: "A quarter for Chloe and me? Thank you so much, girls!",
            auntBye: "Thanks, sis! Chloe and I had a ball — an out-of-this-world ball!"),
    ]
}

/// Each babysitter's first ride (she's always green the first time), in her own words.
struct SitterRide {
    var seeAlien: String
    var ride: RideLines
    var bestJob: String

    static func lines(for name: String) -> SitterRide {
        switch name {
        case "Wanda": SitterRide(
            seeAlien: "Whoa, an actual alien! He's kind of adorable!",
            ride: RideLines(
                spotSaucer: "", inShip: "A real flying saucer! My friends are going to be SO jealous!",
                tingle: "Ooh, it's like pins and needles — the fun kind!",
                legs: "My legs are going green! Wicked!",
                body: "My arms are green now too! This is awesome!",
                faceWarning: "It's climbing up my neck — here it comes!",
                faceComing: "Ooh, my face is getting all tingly!",
                faceLine: "Woo-hoooooooo!",
                mirror: "Check me out! I'm a green Roswell alien!",
                headFeel: "My head is huge and smooth — like a big green jellybean!"),
            bestJob: "Best. Babysitting gig. EVER!")
        case "Donna": SitterRide(
            seeAlien: "An alien! Just like in my comic books!",
            ride: RideLines(
                spotSaucer: "", inShip: "Look at all these blinking lights! It's like a spaceship from the movies!",
                tingle: "Hee hee — that tickles like crazy!",
                legs: "My legs are changing! This is so cool!",
                body: "I'm turning green all over! Far out!",
                faceWarning: "Here it comes — up to my face!",
                faceComing: "My face feels all fizzy, like soda pop!",
                faceLine: "Yahoooooooo!",
                mirror: "No way — I'm a real Roswell alien! I love it!",
                headFeel: "My head is so big — it's like a giant green egg!"),
            bestJob: "I can't wait to come back and babysit again!")
        case "Gloria": SitterRide(
            seeAlien: "Oh my gosh, a real alien! Hello there!",
            ride: RideLines(
                spotSaucer: "", inShip: "I'm actually inside a flying saucer! This is a dream come true!",
                tingle: "Ooh, like a warm, sparkly hug!",
                legs: "My legs are turning green — how pretty!",
                body: "My arms and tummy are green too! I love this color!",
                faceWarning: "Ooh, I can feel it reaching my face!",
                faceComing: "My face is changing — it feels wonderful!",
                faceLine: "Wheeeeeeeeee!",
                mirror: "I'm a Roswell alien — and green looks great on me!",
                headFeel: "My head is so big and smooth — it feels like silk!"),
            bestJob: "This is the most magical babysitting job ever!")
        case "Lynda": SitterRide(
            seeAlien: "A real alien! Okay, girls, I believe you now!",
            ride: RideLines(
                spotSaucer: "", inShip: "I'm on a real flying saucer! This beats the movies any day!",
                tingle: "Ooh, it's all buzzy, like a massage chair!",
                legs: "My legs are going green! Oh, this is fun!",
                body: "My whole body is turning green! Awesome!",
                faceWarning: "Oh, here it comes — my face is next!",
                faceComing: "My face feels all glowy and warm!",
                faceLine: "Yippeeeeeee!",
                mirror: "That's me? I'm a green Roswell alien! Amazing!",
                headFeel: "My head is so big and round — like a green balloon!"),
            bestJob: "Wait till I tell everyone about this babysitting job!")
        case "Laurie": SitterRide(
            seeAlien: "Wow, a real Roswell alien! Nice to meet you!",
            ride: RideLines(
                spotSaucer: "", inShip: "A flying saucer! I've always wanted to go to space!",
                tingle: "Ooh, it's like a thousand tiny bubbles!",
                legs: "Look at my legs — they're turning green!",
                body: "I'm turning green all over! This is so exciting!",
                faceWarning: "It's reaching my face — I'm ready!",
                faceComing: "Ooh, my face is changing! It feels amazing!",
                faceLine: "Wahoooooooo!",
                mirror: "I'm a Roswell alien! This is out of this world!",
                headFeel: "My head is so big and smooth — I feel like a genius!"),
            bestJob: "Out-of-this-world babysitting! I love you girls!")
        default: SitterRide(   // Marcie
            seeAlien: "It's a REAL alien!",
            ride: RideLines(
                spotSaucer: "", inShip: "Wow, I'm really inside a flying saucer! This is amazing — I can't wait!",
                tingle: "This is really tingly!",
                legs: "This feels great!",
                body: "I'm turning green.",
                faceWarning: "Wow!",
                faceComing: "My head is growing",
                faceLine: "and growing",
                mirror: "Wow! I'm a Roswell alien!",
                headFeel: "My head is so big and smooth… and my hair is all gone!"),
            bestJob: "This is the coolest babysitting job ever!")
        }
    }
}
