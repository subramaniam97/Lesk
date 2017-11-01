from string import punctuation
from nltk import word_tokenize, pos_tag
from nltk.corpus import wordnet as wn
from nltk.corpus import stopwords
from lesk import adapted_lesk
from utils import lemmatize, lemmatize_sentence

"""
This is a module for all-words full text WSD

This would involve:
Step 1: First tokenize your text such that each token is separated by whitespace
Step 2: Iterates through the tokens and only disambiguate the content words.
"""

stopwords = stopwords.words('english') + list(punctuation)

def disambiguate(sentence, algorithm=adapted_lesk,
                 context_is_lemmatized=False, similarity_option='path',
                 keepLemmas=False, prefersNone=True):
    tagged_sentence = []
    # Pre-lemmatize the sentence before WSD
    if not context_is_lemmatized:
        surface_words, lemmas, morphy_poss = lemmatize_sentence(sentence, keepWordPOS=True)
        lemma_sentence = " ".join(lemmas)
    else:
        lemma_sentence = sentence # TODO: Miss out on POS specification, how to resolve?
    for word, lemma, pos in zip(surface_words, lemmas, morphy_poss):
        if lemma not in stopwords: # Checks if it is a content word
            try:
                wn.synsets(lemma)[0]
                synset = algorithm(lemma_sentence, lemma, pos=pos, context_is_lemmatized=True)
            except: # In case the content word is not in WordNet
                synset = '#NOT_IN_WN#'
        else:
            synset = '#STOPWORD/PUNCTUATION#'
        if keepLemmas:
            tagged_sentence.append((word, lemma, synset))
        else:
            tagged_sentence.append((word, synset))
    # Change #NOT_IN_WN# and #STOPWORD/PUNCTUATION# into None.
    if prefersNone and not keepLemmas:
        tagged_sentence = [(word, None) if str(tag).startswith('#')
                           else (word, tag) for word, tag in tagged_sentence]
    if prefersNone and keepLemmas:
        tagged_sentence = [(word, lemma, None) if str(tag).startswith('#')
                           else (word, lemma, tag) for word, lemma, tag in tagged_sentence]
    return tagged_sentence


def disambiguateWithHead(sentence, posTarget, algorithm=adapted_lesk,
                 context_is_lemmatized=False, similarity_option='path',
                 keepLemmas=False, prefersNone=True):
    tagged_sentence = []
    reqWord = sentence[posTarget]
    positionOfReqWord = posTarget
    # Pre-lemmatize the sentence before WSD
    if not context_is_lemmatized:
        surface_words, lemmas, morphy_poss = lemmatize_sentence(sentence, keepWordPOS=True)
        lemma_sentence = " ".join(lemmas)
    else:
        lemma_sentence = sentence # TODO: Miss out on POS specification, how to resolve?


    if lemmas[positionOfReqWord] not in stopwords: # Checks if it is a content word
        try:
            synset = algorithm(lemma_sentence, lemmas[positionOfReqWord], pos=morphy_poss[positionOfReqWord], context_is_lemmatized=True)
        except: # In case the content word is not in WordNet
            synset = '#NOT_IN_WN#'
    else:
        synset = '#STOPWORD/PUNCTUATION#'

    if keepLemmas:
        tagged_sentence.append((reqWord, lemmas[positionOfReqWord], synset))
    else:
        tagged_sentence.append((reqWord, synset))



    # Change #NOT_IN_WN# and #STOPWORD/PUNCTUATION# into None.
    if prefersNone and not keepLemmas:
        tagged_sentence = [(word, None) if str(tag).startswith('#')
                           else (word, tag) for word, tag in tagged_sentence]
    if prefersNone and keepLemmas:
        tagged_sentence = [(word, lemma, None) if str(tag).startswith('#')
                           else (word, lemma, tag) for word, lemma, tag in tagged_sentence]
    return tagged_sentence
