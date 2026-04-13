# Tandau платформасы негізінде FinTech құралдарын пайдалана отырып, мамандық пен университетті таңдау жүйесін құру

## 1. Executive Summary
**TANDAU** is a next-generation Career-FinTech platform designed to transform the chaotic process of university admission in Kazakhstan into a structured, data-driven financial investment strategy. By integrating AI-driven consultancy (Google Gemini 1.5 Pro) with advanced financial modeling (`RoiCalculatorService`), TANDAU treats higher education as a high-stakes investment, helping students maximize their Return on Investment (ROI) and secure government grants as key financial assets.

---

## 2. The Problem: Financial Inefficiency in Education
Every year, thousands of students in Kazakhstan choose universities based on incomplete information or emotional bias. This leads to:
- **Capital Waste**: Investing time and money in degrees with low market demand.
- **Grant Misallocation**: Failing to secure government funding despite having eligible scores.
- **Economic Drag**: A mismatch between graduate skills and the labor market.

---

## 3. FinTech Methodology: The TANDAU Approach

### A. ROI (Return on Investment) Calculator
TANDAU features a proprietary ROI service (`RoiCalculatorService`) that evaluates professions and universities as financial assets.
- **Payback Periods**: Models how many months it takes for a graduate to recoup their tuition costs based on starting salaries in Kazakhstan.
- **Career Growth Modeling**: Unlike simple calculators, TANDAU models career evolution: salary multipliers of **1.4x** at year 2 (Middle-level) and **2.0x** at year 5 (Senior-level).
- **Prestige Multiplier**: Top-tier universities (Astana IT, KBTU, Nazarbayev University, Satbayev University, KIMEP) apply a **1.25x** multiplier to the starting base salary.
- **Stipend as Passive Income**: Factors in monthly stipends (Base: **47,135 KZT**; Med/Ped: **75,600 KZT**) with a **15% bonus** for honor students.
- **Taxation & Living Costs**: All net income calculations assume a **21% tax deduction** (Kazakhstan standard) and optional living cost factoring (1,440,000 KZT/year).
- **Rural Quota Optimization**: Accounts for the 15% salary difference in regional placements while modeling the mandatory 3-year "Work-Off" period as a service debt.

### B. The "Grant as an Asset" Strategy
A government grant in Kazakhstan is worth up to **4,000,000 - 12,000,000 KZT** (total tuition). TANDAU treats this as a "Venture Capital" injection into the student's future.
- **Grant Probability Engine**: Uses historical data and automated coefficients to calculate the statistical probability of securing this asset across 50+ universities.
- **Debt Modeling**: Clearly warns students of the "Debt" status if they fail to meet government service requirements for their grants, treating the grant as a conditional liability.
- **Investment Portfolio (NPV)**: Advanced FinTech mode calculates **Net Present Value (NPV)** using a **14% discount rate** (benchmark Kazakhstan bank deposit) to determine the true value of the degree vs. traditional saving.

---

## 4. AI-Driven Financial Guidance
TANDAU integrates **Google Gemini 1.5 Pro** via a custom backend proxy to provide personalized "Zheke Zhospar" (Personal Admission Plans).
- **Contextual Awareness**: The AI analyzes the student's profile (ENT scores, GPA, IELTS, achievements, and financial situation) to recommend the most cost-effective path.
- **Real-time Data Grounding**: Leveraging Google Search Grounding to ensure guidance on grant quotas and deadlines is always current.

---

## 5. Technical Framework (The Engine)
- **Frontend**: Flutter & Dart (Riverpod state management) for a cross-platform (Android/iOS) premium experience.
- **Backend API**: Dart Shelf microservice (deployed on Render) handling secure AI orchestration and heavy data processing.
- **Data Layer**: Cloud Firestore, Local structured academic data, and **E-Gov Kazakhstan Open Data API** (v4) integration for real-time university status monitoring.
- **Comparison Engine**: A specialized `ComparisonService` allowing students to perform side-by-side technical audits of up to **2 universities** simultaneously to find the best financial fit.
- **Payment Integration**: RevenueCat for "PRO" tier access to advanced NPV modeling and detailed AI career strategies.

---

## 6. Psychometric Layer: Career Alignment
Before the financial calculation, TANDAU ensures "Product-Market Fit" for the student through specialized tests:
- **Holland Test**: Mapping personality types to work environments.
- **Klimov Test**: Identifying preferred professional domains.
This ensures the student is not just investing in a lucrative field, but one where they have a natural competitive advantage.

---

## 7. Impact & Future Roadmap
- **Current State**: 50+ Universities, 100+ Specialties, AI streaming responses, and an integrated ROI module.
- **Future (ML-Prediction)**: Moving from heuristic-based grant probabilities to a deep-learning model for even higher accuracy.
- **Expansion**: Scaling the FinTech engine to other Central Asian education markets (Uzbekistan, Kyrgyzstan).

---

## 8. Conclusion for Conference Judges
TANDAU is defining the **Education-FinTech (Ed-Fin)** category. We don't just ask "Where do you want to study?"; we ask "Where will your talent yield the highest socio-economic return?".
