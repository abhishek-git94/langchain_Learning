# AGENTS.md

## Mera kaam: sirf batana, fix karna nahi

Is repo me user seekhna chahta hai. Isliye:

1. **Kabhi bhi code/notebook khud mat badlo.** Na `.ipynb` edit, na `.py` edit, na `pip install`, na file rename/delete.
2. Error mile to sirf ye batao:
   - **Kaunsi cell / line** me error hai
   - **Error kya hai** (ek line me, technical naam ke saath)
   - **Kyun hua** (1-2 line, root cause)
   - **Kya karna hai** (exact fix steps, taaki user khud kare)
3. Chhota sa **proof** de sakte ho (jaise `python -c` se verify karna) — bas repo ki files mat badlo.
4. Guess mat karo. Verify karo (`.venv\Scripts\python.exe` se chala ke dekh lo), phir bolo.
5. Notebook chalane ke liye `.\check.ps1` use karo — ye `.last_error.log` banata hai aur notebook ko chhedta nahi. Direct `nbconvert --inplace` mat chalao.

## Is repo ka context

- Python 3.12, venv: `.venv\Scripts\python.exe`. Purana `venv_OLD_py310_do_not_use` ignore karna.
- `run.ps1` — notebook ko **modify karke** chalta hai (default `DATAingestion.ipynb`). `-NoSave` se check-only.
- `check.ps1` — naya, error log karta hai bina notebook chhede. `.\check.ps1 <notebook.ipynb>` ya `.\check.ps1 -Cell "code"`.
- Libraries: langchain 1.x + `langchain-community` 0.4.2 (deprecated warning aayega, error nahi), `langchain-ollama`, chromadb, faiss-cpu, sentence-transformers.
- Ollama local chal raha hai (port 11434). Embedding models: `mxbai-embed-large`, `nomic-embed-text`. `qwen2.5:1.5b` / `llama3` / `gemma:2b` chat ke liye.
- `.env` me API keys hain — kabhi print/write mat karo.
- Structure: `Data_Transformer/` (splitters, embeddings), `Vector_Store/` (FAISS, ChromaDB).
- `speech.txt` root me hai — `Vector_Store/` wali notebook me path `"../speech.txt"` use karo.

## Style

- User Hinglish me baat karta hai. Chhote, seedhe jawab do.
- Notebook ke comments/outputs English me rakhne ko bol raha hai to English me rakho.
