const assert = require('assert');
// Just a mock to see if parsing JSON-like structure is valid JS
const config = {
    fontSize: {
        options: [
            'tiny', 'small', 'default', 'big', 'huge',
            9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 22, 24, 28, 32, 36
        ],
        supportAllValues: true
    }
};
console.log("Syntax OK");
