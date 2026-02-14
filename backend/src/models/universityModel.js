class University {
    constructor(id, name, city, description, ranking) {
        this.id = id;
        this.name = name;
        this.city = city;
        this.description = description;
        this.ranking = ranking;
    }

    toFirestore() {
        return {
            name: this.name,
            city: this.city,
            description: this.description,
            ranking: this.ranking
        };
    }
}

module.exports = University;
