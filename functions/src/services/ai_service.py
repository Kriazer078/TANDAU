import random

class AIService:
    def __init__(self):
        # Initialize Firebase or any ML clients here if needed
        pass

    def generate_strategy(self, user_unt_score, specialty_id, university_id, user_subjects_scores):
        # This is a sample logic to formulate the strategy based on the prompt requirements

        # 1. GAP Analysis & Simulation (In real app, fetch from Firestore)
        # Mock predicted score for testing
        predicted_min_score_2025 = 95
        specialty_name = "Computer Science"
        university_name = "Tech University"
        
        gap = predicted_min_score_2025 - user_unt_score
        
        description = ""
        alternative_options = []

        if gap <= 0:
            title = "Отличные шансы на поступление!"
            description += f"Твой текущий балл ({user_unt_score}) уже превышает прогнозируемый проходной балл ({predicted_min_score_2025}) на специальность {specialty_name}.\n\n"
            description += "Продолжай в том же духе. Повторяй пройденный материал и не забывай про отдых, чтобы не перегореть.\n"
        else:
            title = "Стратегия подготовки: Нужно поднажать!"
            description += f"Тебе не хватает около {gap} баллов до прогнозируемого проходного балла ({predicted_min_score_2025}) на специальность {specialty_name}.\n\n"
            
            # Subject-specific advice
            if user_subjects_scores:
                weak_subjects = [s for s, score in user_subjects_scores.items() if score < 20] # Assume out of 40 for simple simulation
                if weak_subjects:
                    description += f"Твои слабые зоны: {', '.join(weak_subjects)}. Сосредоточься на них.\n\n"
            
            description += "Рекомендации:\n"
            description += "• Анализируй ошибки: проходи пробные тесты 2 раза в неделю.\n"
            description += "• Обрати внимание на YouTube-уроки по западающим темам (Сложные логарифмы, механика и т.д.).\n"
            description += "• Разбей подготовку: уделяй 80% времени слабым темам и 20% на повторение сильных сторон.\n"

        # Alternative Options (suggested if gap > 10)
        if gap > 10:
            description += "\nЕсли ты переживаешь за грант, вот несколько альтернативных вариантов с более доступными баллами:"
            alternative_options = [
                {
                    "university_name": "Satbayev University",
                    "specialty_name": "Information Systems",
                    "probability": 75
                },
                {
                    "university_name": "AITU",
                    "specialty_name": "IT Management",
                    "probability": 82
                }
            ]

        # Motivational Tone
        description += "\n\nВерь в себя! У тебя есть все шансы достичь своей цели. Главное — регулярность и правильный настрой! 🚀"

        return {
            "title": title,
            "description": description,
            "alternative_options": alternative_options
        }
